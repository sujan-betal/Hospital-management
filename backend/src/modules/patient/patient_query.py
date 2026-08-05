"""Low-level database query and formatting helpers for the Patient module.

Kept separate from the business logic in `patient_service.py` so the
service layer stays clean and each helper is reusable.
"""

import re
import random
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.doctor_model import Doctor
from src.models.doctor_review_model import DoctorReview
from src.models.invoice_model import Invoice
from src.models.opd_appointment_model import OpdAppointment
from src.models.patient_model import Patient


def normalize_phone(value: str) -> str:
    """Strip everything except digits so phone matching is forgiving."""
    return re.sub(r"\D", "", value or "")


def patient_to_dict(patient: Patient) -> dict:
    return {
        "id": patient.id,
        "user_id": str(patient.user_id),
        "user_name": patient.user_name,
        "name": patient.user_name,
        "email": patient.email or "",
        "phone": patient.phone,
        "age": patient.age,
        "gender": patient.gender,
        "insurance_provider": patient.insurance_provider or "Self-Pay / None",
        "status": patient.status,
        "role": patient.role,
        "created_at": patient.created_at,
        "updated_at": patient.updated_at,
    }


async def find_patient_by_user_id(db: AsyncSession, user_id):
    result = await db.execute(select(Patient).where(Patient.user_id == user_id))
    return result.scalar_one_or_none()


async def find_patient_by_phone(db: AsyncSession, phone: str):
    result = await db.execute(select(Patient).where(Patient.phone == phone))
    return result.scalar_one_or_none()


async def find_patient_by_phone_normalized(db: AsyncSession, phone: str):
    """Match a patient by phone, ignoring spacing/punctuation differences."""
    normalized = normalize_phone(phone)
    patients = (await db.execute(select(Patient))).scalars().all()
    for patient in patients:
        if normalize_phone(patient.phone or "") == normalized:
            return patient
    return None


def set_patient_otp(patient: Patient, otp_code: str, expiry: datetime) -> None:
    """Persist the hashed OTP and its expiry onto a patient record."""
    patient.otp_code = otp_code
    patient.otp_expiry = expiry


def clear_patient_otp(patient: Patient) -> None:
    patient.otp_code = None
    patient.otp_expiry = None


# ─────────────────────── Patient records (appointments / invoices) ───────────────────────

def appointment_to_dict(appt: OpdAppointment) -> dict:
    return {
        "id": appt.id,
        "appointment_id": appt.appointment_id,
        "patient_name": appt.patient_name,
        "patient_phone": appt.patient_phone or "",
        "patient_user_id": appt.patient_user_id or "",
        "doctor_name": appt.doctor_name,
        "specialty": appt.specialty,
        "date": appt.date,
        "time": appt.time,
        "status": appt.status,
        "fee": appt.fee or 150,
        "payment_status": appt.payment_status or "UNPAID",
        "payment_id": appt.payment_id or "",
        "razorpay_order_id": appt.razorpay_order_id or "",
        "doctor_share_percent": appt.doctor_share_percent or 0,
        "admin_share": appt.admin_share or 0,
        "doctor_share": appt.doctor_share or 0,
        "payout_status": appt.payout_status or "NOT_CONFIGURED",
        "payout_id": appt.payout_id or "",
        "payout_error": appt.payout_error or "",
        "payout_date": appt.payout_date.isoformat() if appt.payout_date else "",
        "created_at": appt.created_at,
        "updated_at": appt.updated_at,
    }


async def find_appointment_by_appointment_id(
    db: AsyncSession, appointment_id: str
) -> OpdAppointment | None:
    result = await db.execute(
        select(OpdAppointment).where(
            OpdAppointment.appointment_id == appointment_id
        )
    )
    return result.scalar_one_or_none()


async def find_slot_booking(
    db: AsyncSession,
    doctor_name: str,
    date: str,
    time: str,
    exclude_appointment_id: str | None = None,
) -> OpdAppointment | None:
    """Return an ACTIVE appointment that already holds the given
    doctor/date/time slot, so the same time can't be booked twice."""
    query = select(OpdAppointment).where(
        OpdAppointment.doctor_name == doctor_name,
        OpdAppointment.date == date,
        OpdAppointment.time == time,
        OpdAppointment.status != "CANCELLED",
    )
    if exclude_appointment_id:
        query = query.where(
            OpdAppointment.appointment_id != exclude_appointment_id
        )
    result = await db.execute(query)
    return result.scalars().first()


def patient_owns_appointment(appt: OpdAppointment, patient: Patient) -> bool:
    """Check that an appointment belongs to the logged-in patient. Newer
    bookings store the patient user_id; older ones are matched by phone."""
    if appt.patient_user_id:
        return appt.patient_user_id == str(patient.user_id)
    if patient.phone and appt.patient_phone:
        return normalize_phone(appt.patient_phone) == normalize_phone(patient.phone)
    if patient.user_name:
        return (appt.patient_name or "").strip().lower() == patient.user_name.strip().lower()
    return False


async def find_booked_slots(db: AsyncSession, date: str) -> list:
    """Return every active (doctor_name, time) pair already taken on a date,
    so the booking UI can disable slots booked by anyone."""
    result = await db.execute(
        select(OpdAppointment.doctor_name, OpdAppointment.time).where(
            OpdAppointment.date == date,
            OpdAppointment.status != "CANCELLED",
        )
    )
    return [
        {"doctor_name": row[0], "time": row[1]}
        for row in result.all()
    ]


def invoice_to_dict(invoice: Invoice) -> dict:
    import json

    items = []
    if invoice.items:
        try:
            parsed = json.loads(invoice.items)
            if isinstance(parsed, list):
                items = parsed
        except Exception:
            pass
    return {
        "id": invoice.id,
        "invoice_id": invoice.invoice_id,
        "patient_name": invoice.patient_name,
        "patient_phone": invoice.patient_phone or "",
        "date": invoice.date,
        "amount": invoice.amount,
        "items": items,
        "insurance_status": invoice.insurance_status,
        "payment_status": invoice.payment_status,
        "created_at": invoice.created_at,
        "updated_at": invoice.updated_at,
    }


async def list_active_doctors(db: AsyncSession) -> list:
    """Return ACTIVE doctors for the patient booking directory."""
    doctors = (
        (await db.execute(select(Doctor).where(Doctor.status == "ACTIVE")))
        .scalars()
        .all()
    )
    return [
        {
            "user_id": str(doc.user_id),
            "name": doc.user_name,
            "specialty": doc.department or "General Medicine",
            "department": doc.department,
            "email": doc.email,
            "phone": doc.phone,
            "rating": round(float(doc.rating), 1) if doc.rating is not None else 4.0,
            "review_count": doc.review_count or 0,
            "experience_years": doc.experience_years or 0,
            "is_top_rated": (doc.rating or 4.0) >= 4.5,
        }
        for doc in doctors
    ]


async def find_patient_appointments(db: AsyncSession, patient: Patient) -> list:
    """Return the patient's OPD appointments, matched primarily by phone
    and falling back to their display name."""
    user_id = str(patient.user_id)
    phone = normalize_phone(patient.phone or "")
    name = (patient.user_name or "").strip().lower()
    appointments = (
        (
            await db.execute(
                select(OpdAppointment).order_by(
                    OpdAppointment.date.desc(), OpdAppointment.id.desc()
                )
            )
        )
        .scalars()
        .all()
    )
    matches = []
    for appt in appointments:
        appt_phone = normalize_phone(appt.patient_phone or "")
        appt_name = (appt.patient_name or "").strip().lower()
        if appt.patient_user_id and appt.patient_user_id == user_id:
            matches.append(appt)
        elif phone and appt_phone == phone:
            matches.append(appt)
        elif phone and not appt_phone and name and appt_name == name:
            matches.append(appt)
        elif not phone and name and appt_name == name:
            matches.append(appt)
    return matches


async def find_patient_invoices(db: AsyncSession, patient: Patient) -> list:
    """Return the patient's invoices, matched primarily by phone and
    falling back to their display name."""
    phone = normalize_phone(patient.phone or "")
    name = (patient.user_name or "").strip().lower()
    invoices = (
        (
            await db.execute(
                select(Invoice).order_by(Invoice.created_at.desc())
            )
        )
        .scalars()
        .all()
    )
    matches = []
    for invoice in invoices:
        inv_phone = normalize_phone(invoice.patient_phone or "")
        inv_name = (invoice.patient_name or "").strip().lower()
        if phone and inv_phone == phone:
            matches.append(invoice)
        elif phone and not inv_phone and name and inv_name == name:
            matches.append(invoice)
        elif not phone and name and inv_name == name:
            matches.append(invoice)
    return matches


# ─────────────────────── Doctor reviews ───────────────────────

async def generate_review_id(db: AsyncSession) -> str:
    """Create a unique public review id like REV-1234."""
    for _ in range(30):
        value = f"REV-{random.randint(1000, 9999)}"
        result = await db.execute(
            select(DoctorReview.id).where(DoctorReview.review_id == value)
        )
        if result.scalar_one_or_none() is None:
            return value
    return f"REV-{uuid.uuid4().hex[:6].upper()}"


def review_to_dict(review: DoctorReview) -> dict:
    return {
        "id": review.id,
        "review_id": review.review_id,
        "appointment_id": review.appointment_id,
        "doctor_id": review.doctor_id or "",
        "doctor_name": review.doctor_name,
        "specialty": review.specialty or "",
        "patient_user_id": review.patient_user_id,
        "patient_name": review.patient_name or "",
        "rating": review.rating,
        "comment": review.comment or "",
        "created_at": review.created_at,
        "updated_at": review.updated_at,
    }


async def find_review_by_appointment(
    db: AsyncSession, appointment_id: str
) -> DoctorReview | None:
    result = await db.execute(
        select(DoctorReview).where(
            DoctorReview.appointment_id == appointment_id
        )
    )
    return result.scalar_one_or_none()


async def find_patient_reviews(db: AsyncSession, patient: Patient) -> list:
    """Return every review the patient has left, newest first."""
    reviews = (
        (
            await db.execute(
                select(DoctorReview)
                .where(DoctorReview.patient_user_id == str(patient.user_id))
                .order_by(DoctorReview.created_at.desc())
            )
        )
        .scalars()
        .all()
    )
    return [review_to_dict(r) for r in reviews]


async def find_doctor_by_name(db: AsyncSession, doctor_name: str) -> Doctor | None:
    result = await db.execute(
        select(Doctor).where(Doctor.user_name == doctor_name)
    )
    return result.scalar_one_or_none()


async def recompute_doctor_rating(db: AsyncSession, doctor: Doctor, new_rating: int) -> None:
    """Fold a new review into a doctor's aggregate rating as a weighted
    average against the existing baseline (seeded + prior real reviews),
    so the directory rating and review count grow smoothly."""
    prev_rating = float(doctor.rating) if doctor.rating is not None else 4.0
    prev_count = int(doctor.review_count) if doctor.review_count is not None else 0
    new_count = prev_count + 1
    doctor.rating = round(
        ((prev_rating * prev_count) + new_rating) / new_count, 2
    )
    doctor.review_count = new_count
