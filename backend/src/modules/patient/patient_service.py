"""Business logic for the Patient module.

All patient-related operations live here — staff creation, OTP login and
profile management. Low-level DB helpers live in `patient_query.py`.
"""

import json
import os

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.doctor_review_model import DoctorReview
from src.models.invoice_model import Invoice
from src.models.opd_appointment_model import OpdAppointment
from src.models.patient_model import Patient
from src.modules.patient.patient_query import (
    appointment_to_dict,
    clear_patient_otp,
    find_appointment_by_appointment_id,
    find_booked_slots,
    find_doctor_by_name,
    find_patient_appointments,
    find_patient_by_phone,
    find_patient_by_phone_normalized,
    find_patient_by_user_id,
    find_patient_invoices,
    find_patient_reviews,
    find_review_by_appointment,
    find_slot_booking,
    generate_review_id,
    invoice_to_dict,
    list_active_doctors,
    patient_owns_appointment,
    patient_to_dict,
    recompute_doctor_rating,
    review_to_dict,
    set_patient_otp,
)
from src.modules.patient.patient_schema import (
    PatientAppointmentCreateRequest,
    PatientAppointmentUpdateRequest,
    PatientCreateRequest,
    PatientOtpSendRequest,
    PatientOtpVerifyRequest,
    PatientPaymentVerifyRequest,
    PatientReviewCreateRequest,
    PatientUpdateRequest,
)
from src.utils.common_schema import api_response_error, api_response_success
from src.utils.otp import (
    OTP_TTL_MINUTES,
    generate_otp,
    is_otp_expired,
    otp_expiry_utc,
    send_otp_to_phone,
)
from src.utils.security import create_access_token, get_password_hash, verify_password
from src.utils.status_code import StatusCode

VALID_PATIENT_STATUSES = {"ACTIVE", "INACTIVE", "SUSPENDED"}


def _dev_mode() -> bool:
    return os.getenv("APP_ENV", "development") != "production"


# ─────────────────────── Staff creates a patient ───────────────────────

async def create_patient_service(payload: PatientCreateRequest, db: AsyncSession):
    """Admin/receptionist creates a patient. The patient later logs in with
    a phone OTP, so no password is stored."""
    try:
        if await find_patient_by_phone(db, payload.phone):
            return api_response_error(
                message="A patient with this phone number is already registered",
                status_code=StatusCode.conflict,
            )

        if payload.user_name:
            result = await db.execute(
                select(Patient).where(Patient.user_name == payload.user_name)
            )
            if result.scalar_one_or_none():
                return api_response_error(
                    message="Username already exists",
                    status_code=StatusCode.conflict,
                )

        patient = Patient(
            user_name=payload.user_name,
            email=payload.email or None,
            phone=payload.phone,
            password=None,
            age=payload.age,
            gender=payload.gender,
            insurance_provider=payload.insurance_provider,
            role="PATIENT",
            status="ACTIVE",
        )
        db.add(patient)
        await db.commit()
        await db.refresh(patient)

        return api_response_success(
            data=patient_to_dict(patient),
            message=f"Patient {patient.user_name} registered successfully",
            status_code=StatusCode.create,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to register patient: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── OTP login flow ───────────────────────

async def send_otp_service(payload: PatientOtpSendRequest, db: AsyncSession):
    """Send a login OTP to a phone number.

    No pre-registration is required — a patient account is created on the
    fly the first time a phone number requests an OTP.
    """
    try:
        patient = await find_patient_by_phone_normalized(db, payload.phone)
        if not patient:
            # Self-registration: the account is created on first login, so
            # the patient just needs their phone number.
            patient = Patient(
                user_name=None,
                email=None,
                phone=payload.phone,
                password=None,
                role="PATIENT",
                status="ACTIVE",
            )
            db.add(patient)
            await db.flush()

        if patient.status != "ACTIVE":
            return api_response_error(
                message=f"Account status is {patient.status}",
                status_code=StatusCode.forbidden,
            )

        otp = generate_otp()
        set_patient_otp(patient, get_password_hash(otp), otp_expiry_utc())
        await db.commit()

        send_otp_to_phone(patient.phone or payload.phone, otp)

        data = {
            "phone": patient.phone,
            "patient_name": patient.user_name,
            "expires_in": OTP_TTL_MINUTES * 60,
        }
        if _dev_mode():
            # No SMS provider is configured yet, so surface the code to the
            # caller to keep the demo login flow working end-to-end.
            data["otp"] = otp

        return api_response_success(
            data=data,
            message="OTP sent successfully to your registered phone number",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to send OTP: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def verify_otp_service(payload: PatientOtpVerifyRequest, db: AsyncSession):
    """Verify the OTP and, on success, issue a patient access token."""
    try:
        patient = await find_patient_by_phone_normalized(db, payload.phone)
        if not patient:
            return api_response_error(
                message="No patient account is registered with this phone number",
                status_code=StatusCode.notFound,
            )

        if not patient.otp_code:
            return api_response_error(
                message="No OTP has been requested for this number",
                status_code=StatusCode.badRequest,
            )

        if is_otp_expired(patient.otp_expiry):
            clear_patient_otp(patient)
            await db.commit()
            return api_response_error(
                message="OTP has expired. Please request a new one.",
                status_code=StatusCode.badRequest,
            )

        if not verify_password(payload.otp, patient.otp_code):
            return api_response_error(
                message="Invalid OTP. Please check and try again.",
                status_code=StatusCode.badRequest,
            )

        clear_patient_otp(patient)
        await db.commit()
        await db.refresh(patient)

        patient_data = patient_to_dict(patient)
        patient_data["access_token"] = create_access_token(
            subject=patient.user_id, role=patient.role
        )
        patient_data["token_type"] = "bearer"

        return api_response_success(
            data=patient_data,
            message="OTP verified. Login successful.",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"OTP verification failed: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Self-service profile ───────────────────────

async def get_patient_profile_service(current_patient, db: AsyncSession):
    try:
        patient = await find_patient_by_user_id(db, current_patient.user_id)
        if not patient:
            return api_response_error(
                message="Patient not found",
                status_code=StatusCode.notFound,
            )

        return api_response_success(
            data=patient_to_dict(patient),
            message="Patient profile fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch profile: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_patient_profile_service(current_patient, payload: PatientUpdateRequest, db: AsyncSession):
    try:
        patient = await find_patient_by_user_id(db, current_patient.user_id)
        if not patient:
            return api_response_error(
                message="Patient not found",
                status_code=StatusCode.notFound,
            )

        if payload.phone is not None and payload.phone != patient.phone:
            if await find_patient_by_phone(db, payload.phone):
                return api_response_error(
                    message="A patient with this phone number is already registered",
                    status_code=StatusCode.conflict,
                )
            patient.phone = payload.phone

        if payload.user_name is not None:
            patient.user_name = payload.user_name
        if payload.email is not None:
            patient.email = payload.email or None
        if payload.age is not None:
            patient.age = payload.age
        if payload.gender is not None:
            patient.gender = payload.gender
        if payload.insurance_provider is not None:
            patient.insurance_provider = payload.insurance_provider

        await db.commit()
        await db.refresh(patient)

        return api_response_success(
            data=patient_to_dict(patient),
            message="Patient profile updated successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update profile: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Self-service appointments & billing ───────────────────────

async def list_patient_doctors_service(db: AsyncSession):
    """Return ACTIVE doctors for the patient booking directory."""
    try:
        doctors = await list_active_doctors(db)
        return api_response_success(
            data=doctors,
            message="Doctors fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch doctors: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def list_patient_appointments_service(current_patient, db: AsyncSession):
    """Return the logged-in patient's OPD appointments."""
    try:
        patient = await find_patient_by_user_id(db, current_patient.user_id)
        if not patient:
            return api_response_error(
                message="Patient not found",
                status_code=StatusCode.notFound,
            )

        appointments = await find_patient_appointments(db, patient)
        return api_response_success(
            data=[appointment_to_dict(a) for a in appointments],
            message="Appointments fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch appointments: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def list_booked_slots_service(date: str, db: AsyncSession):
    """Return all active doctor/time slots already booked for a date so the
    booking UI can grey them out."""
    try:
        slots = await find_booked_slots(db, date)
        return api_response_success(
            data=slots,
            message="Booked slots fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch booked slots: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def list_patient_invoices_service(current_patient, db: AsyncSession):
    """Return the logged-in patient's invoices/bills."""
    try:
        patient = await find_patient_by_user_id(db, current_patient.user_id)
        if not patient:
            return api_response_error(
                message="Patient not found",
                status_code=StatusCode.notFound,
            )

        invoices = await find_patient_invoices(db, patient)
        return api_response_success(
            data=[invoice_to_dict(inv) for inv in invoices],
            message="Invoices fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch invoices: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Doctor reviews ───────────────────────

async def list_patient_reviews_service(current_patient, db: AsyncSession):
    """Return every review the logged-in patient has left."""
    try:
        patient = await find_patient_by_user_id(db, current_patient.user_id)
        if not patient:
            return api_response_error(
                message="Patient not found",
                status_code=StatusCode.notFound,
            )
        reviews = await find_patient_reviews(db, patient)
        return api_response_success(
            data=reviews,
            message="Reviews fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch reviews: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def submit_doctor_review_service(
    current_patient,
    payload: PatientReviewCreateRequest,
    db: AsyncSession,
):
    """Let a patient rate + comment on a doctor after their visit. The
    doctor is resolved from the appointment, and the visit must be marked
    CHECKED-IN or COMPLETED before a review is accepted."""
    try:
        patient = await find_patient_by_user_id(db, current_patient.user_id)
        if not patient:
            return api_response_error(
                message="Patient not found",
                status_code=StatusCode.notFound,
            )

        appt = await find_appointment_by_appointment_id(db, payload.appointment_id)
        if not appt or not patient_owns_appointment(appt, patient):
            return api_response_error(
                message="Appointment not found",
                status_code=StatusCode.notFound,
            )

        if appt.status.upper() not in {"CHECKED-IN", "COMPLETED"}:
            return api_response_error(
                message=(
                    "You can only review a doctor after your consultation "
                    "has been completed."
                ),
                status_code=StatusCode.badRequest,
            )

        if await find_review_by_appointment(db, appt.appointment_id):
            return api_response_error(
                message="You have already reviewed this visit",
                status_code=StatusCode.conflict,
            )

        doctor = await find_doctor_by_name(db, appt.doctor_name)
        review = DoctorReview(
            review_id=await generate_review_id(db),
            appointment_id=appt.appointment_id,
            doctor_id=str(doctor.user_id) if doctor else None,
            doctor_name=appt.doctor_name,
            specialty=appt.specialty,
            patient_user_id=str(patient.user_id),
            patient_name=patient.user_name,
            rating=payload.rating,
            comment=(payload.comment or "").strip() or None,
        )
        db.add(review)
        if doctor:
            await recompute_doctor_rating(db, doctor, payload.rating)
        await db.commit()
        await db.refresh(review)

        return api_response_success(
            data=review_to_dict(review),
            message=(
                f"Thank you for rating {appt.doctor_name}! "
                f"Your feedback has been saved."
            ),
            status_code=StatusCode.create,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to submit review: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def book_appointment_service(current_patient, payload: PatientAppointmentCreateRequest, db: AsyncSession):
    """Let a logged-in patient book an OPD slot. Identity comes from the
    authenticated account so the appointment links back to the patient."""
    try:
        from src.modules.receptionist.receptionist_query import (
            generate_appointment_id,
            generate_invoice_id,
        )

        patient = await find_patient_by_user_id(db, current_patient.user_id)
        if not patient:
            return api_response_error(
                message="Patient not found",
                status_code=StatusCode.notFound,
            )

        if not patient.user_name:
            return api_response_error(
                message="Please set your name in the Profile tab before booking",
                status_code=StatusCode.badRequest,
            )

        existing_slot = await find_slot_booking(
            db, payload.doctor_name, payload.date, payload.time
        )
        if existing_slot:
            return api_response_error(
                message=(
                    f"This time slot is already booked for {payload.doctor_name} "
                    f"on {payload.date}. Please pick another time."
                ),
                status_code=StatusCode.conflict,
            )

        appt = OpdAppointment(
            appointment_id=await generate_appointment_id(db),
            patient_name=patient.user_name,
            patient_phone=patient.phone,
            patient_user_id=str(patient.user_id),
            doctor_name=payload.doctor_name,
            specialty=payload.specialty,
            date=payload.date,
            time=payload.time,
            status="SCHEDULED",
            fee=150,
            payment_status="UNPAID",
        )
        db.add(appt)
        try:
            await db.commit()
        except IntegrityError:
            await db.rollback()
            return api_response_error(
                message=(
                    f"This time slot was just booked for {payload.doctor_name} "
                    f"on {payload.date}. Please pick another time."
                ),
                status_code=StatusCode.conflict,
            )
        await db.refresh(appt)

        return api_response_success(
            data=appointment_to_dict(appt),
            message=f"Appointment {appt.appointment_id} booked successfully",
            status_code=StatusCode.create,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to book appointment: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_patient_appointment_service(
    current_patient, appointment_id: str, payload: PatientAppointmentUpdateRequest, db: AsyncSession
):
    """Let a patient reschedule their own appointment (new date/time)."""
    try:
        appt = await find_appointment_by_appointment_id(db, appointment_id)
        if not appt:
            return api_response_error(
                message="Appointment not found",
                status_code=StatusCode.notFound,
            )

        patient = await find_patient_by_user_id(db, current_patient.user_id)
        if not patient or not patient_owns_appointment(appt, patient):
            return api_response_error(
                message="Appointment not found",
                status_code=StatusCode.notFound,
            )

        if appt.status.upper() == "CANCELLED":
            return api_response_error(
                message="Cancelled appointments cannot be edited",
                status_code=StatusCode.badRequest,
            )

        new_date = payload.date if payload.date is not None else appt.date
        new_time = payload.time if payload.time is not None else appt.time
        new_doctor = (
            payload.doctor_name if payload.doctor_name is not None else appt.doctor_name
        )

        if (
            payload.date is not None
            or payload.time is not None
            or payload.doctor_name is not None
        ):
            conflict = await find_slot_booking(
                db,
                new_doctor,
                new_date,
                new_time,
                exclude_appointment_id=appt.appointment_id,
            )
            if conflict:
                return api_response_error(
                    message=(
                        f"This time slot is already booked for {new_doctor} "
                        f"on {new_date}. Please pick another time."
                    ),
                    status_code=StatusCode.conflict,
                )

        if payload.doctor_name is not None:
            appt.doctor_name = payload.doctor_name
        if payload.specialty is not None:
            appt.specialty = payload.specialty
        if payload.date is not None:
            appt.date = payload.date
        if payload.time is not None:
            appt.time = payload.time

        try:
            await db.commit()
        except IntegrityError:
            await db.rollback()
            return api_response_error(
                message=(
                    f"This time slot was just booked for {new_doctor} "
                    f"on {new_date}. Please pick another time."
                ),
                status_code=StatusCode.conflict,
            )
        await db.refresh(appt)

        return api_response_success(
            data=appointment_to_dict(appt),
            message=f"Appointment {appt.appointment_id} rescheduled successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update appointment: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Razorpay payments ───────────────────────

def _razorpay_client():
    key_id = os.getenv("RAZORPAY_KEY_ID", "").strip().strip("'")
    key_secret = os.getenv("RAZORPAY_KEY_SECRET", "").strip().strip("'")
    if not key_id or not key_secret:
        return None, None
    try:
        import razorpay
    except ImportError:
        return None, None
    return razorpay.Client(auth=(key_id, key_secret)), key_id


async def create_payment_order_service(
    current_patient, appointment_id: str, db: AsyncSession
):
    """Create a Razorpay order for the appointment's OPD consultation fee."""
    try:
        appt = await find_appointment_by_appointment_id(db, appointment_id)
        if not appt:
            return api_response_error(
                message="Appointment not found",
                status_code=StatusCode.notFound,
            )

        patient = await find_patient_by_user_id(db, current_patient.user_id)
        if not patient or not patient_owns_appointment(appt, patient):
            return api_response_error(
                message="Appointment not found",
                status_code=StatusCode.notFound,
            )

        if appt.status.upper() == "CANCELLED":
            return api_response_error(
                message="Cancelled appointments cannot be paid for",
                status_code=StatusCode.badRequest,
            )
        if appt.payment_status.upper() == "PAID":
            return api_response_error(
                message="This appointment is already paid",
                status_code=StatusCode.conflict,
            )

        client, key_id = _razorpay_client()
        if client is None or not key_id:
            return api_response_error(
                message="Razorpay is not configured. Please contact the front desk.",
                status_code=StatusCode.internalServerError,
            )

        fee = appt.fee or 150
        order = client.order.create({
            "amount": fee * 100,
            "currency": "INR",
            "receipt": appt.appointment_id,
            "payment_capture": 1,
            "notes": {"appointment_id": appt.appointment_id},
        })

        appt.razorpay_order_id = order.get("id")
        await db.commit()

        return api_response_success(
            data={
                "key_id": key_id,
                "order_id": order.get("id"),
                "amount": order.get("amount", fee * 100),
                "currency": order.get("currency", "INR"),
                "receipt": appt.appointment_id,
                "appointment_id": appt.appointment_id,
            },
            message="Payment order created successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to create payment order: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def verify_payment_service(
    current_patient,
    appointment_id: str,
    payload: PatientPaymentVerifyRequest,
    db: AsyncSession,
):
    """Verify the Razorpay signature, mark the appointment PAID and raise a
    matching invoice so it also shows under Bills & Invoices."""
    try:
        from src.modules.receptionist.receptionist_query import (
            generate_invoice_id,
        )

        appt = await find_appointment_by_appointment_id(db, appointment_id)
        if not appt:
            return api_response_error(
                message="Appointment not found",
                status_code=StatusCode.notFound,
            )

        patient = await find_patient_by_user_id(db, current_patient.user_id)
        if not patient or not patient_owns_appointment(appt, patient):
            return api_response_error(
                message="Appointment not found",
                status_code=StatusCode.notFound,
            )

        client, _ = _razorpay_client()
        if client is None:
            return api_response_error(
                message="Razorpay is not configured. Please contact the front desk.",
                status_code=StatusCode.internalServerError,
            )

        try:
            client.utility.verify_payment_signature({
                "razorpay_order_id": payload.razorpay_order_id,
                "razorpay_payment_id": payload.razorpay_payment_id,
                "razorpay_signature": payload.razorpay_signature,
            })
        except Exception:
            return api_response_error(
                message="Payment verification failed. Please try again.",
                status_code=StatusCode.badRequest,
            )

        if appt.payment_status.upper() == "PAID":
            return api_response_success(
                data={"appointment": appointment_to_dict(appt), "invoice": None},
                message="Payment already confirmed for this appointment",
                status_code=StatusCode.success,
            )

        appt.payment_status = "PAID"
        appt.payment_id = payload.razorpay_payment_id
        appt.payment_signature = payload.razorpay_signature

        fee = appt.fee or 150
        invoice = Invoice(
            invoice_id=await generate_invoice_id(db),
            patient_name=appt.patient_name,
            patient_phone=appt.patient_phone,
            date=appt.date,
            amount=fee,
            items=json.dumps([
                {"description": f"OPD Consultation – {appt.doctor_name}", "cost": fee}
            ]),
            insurance_status="UNINSURED",
            payment_status="PAID",
        )
        db.add(invoice)

        try:
            await db.commit()
        except Exception:
            await db.rollback()
            return api_response_error(
                message="Could not confirm your payment. Please contact the front desk.",
                status_code=StatusCode.internalServerError,
            )
        await db.refresh(appt)

        return api_response_success(
            data={"appointment": appointment_to_dict(appt), "invoice": invoice_to_dict(invoice)},
            message="Payment successful. Your appointment is confirmed.",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to verify payment: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Staff/admin patient management ───────────────────────

async def list_patients_service(db: AsyncSession):
    try:
        patients = (
            (await db.execute(
                select(Patient).order_by(Patient.created_at.desc())
            ))
            .scalars()
            .all()
        )
        return api_response_success(
            data=[patient_to_dict(p) for p in patients],
            message="Patients fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch patients: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def get_patient_service(user_id, db: AsyncSession):
    try:
        patient = await find_patient_by_user_id(db, user_id)
        if not patient:
            return api_response_error(
                message="Patient not found",
                status_code=StatusCode.notFound,
            )

        return api_response_success(
            data=patient_to_dict(patient),
            message="Patient fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch patient: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_patient_service(user_id, payload: PatientUpdateRequest, db: AsyncSession):
    try:
        patient = await find_patient_by_user_id(db, user_id)
        if not patient:
            return api_response_error(
                message="Patient not found",
                status_code=StatusCode.notFound,
            )

        if payload.phone is not None and payload.phone != patient.phone:
            if await find_patient_by_phone(db, payload.phone):
                return api_response_error(
                    message="A patient with this phone number is already registered",
                    status_code=StatusCode.conflict,
                )
            patient.phone = payload.phone

        if payload.user_name is not None:
            patient.user_name = payload.user_name
        if payload.email is not None:
            patient.email = payload.email or None
        if payload.age is not None:
            patient.age = payload.age
        if payload.gender is not None:
            patient.gender = payload.gender
        if payload.insurance_provider is not None:
            patient.insurance_provider = payload.insurance_provider
        if payload.status is not None and payload.status.upper() in VALID_PATIENT_STATUSES:
            patient.status = payload.status.upper()

        await db.commit()
        await db.refresh(patient)

        return api_response_success(
            data=patient_to_dict(patient),
            message="Patient updated successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update patient: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def delete_patient_service(user_id, db: AsyncSession):
    try:
        patient = await find_patient_by_user_id(db, user_id)
        if not patient:
            return api_response_error(
                message="Patient not found",
                status_code=StatusCode.notFound,
            )

        await db.delete(patient)
        await db.commit()

        return api_response_success(
            data=None,
            message="Patient record deleted permanently",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to delete patient: {str(e)}",
            status_code=StatusCode.internalServerError,
        )
