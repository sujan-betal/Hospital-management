"""Business logic for the Patient module.

All patient-related operations live here — staff creation, OTP login and
profile management. Low-level DB helpers live in `patient_query.py`.
"""

import os

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.opd_appointment_model import OpdAppointment
from src.models.patient_model import Patient
from src.modules.patient.patient_query import (
    appointment_to_dict,
    clear_patient_otp,
    find_patient_appointments,
    find_patient_by_phone,
    find_patient_by_phone_normalized,
    find_patient_by_user_id,
    find_patient_invoices,
    invoice_to_dict,
    list_active_doctors,
    patient_to_dict,
    set_patient_otp,
)
from src.modules.patient.patient_schema import (
    PatientAppointmentCreateRequest,
    PatientCreateRequest,
    PatientOtpSendRequest,
    PatientOtpVerifyRequest,
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


async def book_appointment_service(current_patient, payload: PatientAppointmentCreateRequest, db: AsyncSession):
    """Let a logged-in patient book an OPD slot. Identity comes from the
    authenticated account so the appointment links back to the patient."""
    try:
        from src.modules.receptionist.receptionist_query import (
            generate_appointment_id,
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

        appt = OpdAppointment(
            appointment_id=await generate_appointment_id(db),
            patient_name=patient.user_name,
            patient_phone=patient.phone,
            doctor_name=payload.doctor_name,
            specialty=payload.specialty,
            date=payload.date,
            time=payload.time,
            status="SCHEDULED",
        )
        db.add(appt)
        await db.commit()
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
