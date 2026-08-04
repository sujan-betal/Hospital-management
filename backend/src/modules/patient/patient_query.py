"""Low-level database query and formatting helpers for the Patient module.

Kept separate from the business logic in `patient_service.py` so the
service layer stays clean and each helper is reusable.
"""

import re
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.doctor_model import Doctor
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
        "doctor_name": appt.doctor_name,
        "specialty": appt.specialty,
        "date": appt.date,
        "time": appt.time,
        "status": appt.status,
        "created_at": appt.created_at,
        "updated_at": appt.updated_at,
    }


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
        }
        for doc in doctors
    ]


async def find_patient_appointments(db: AsyncSession, patient: Patient) -> list:
    """Return the patient's OPD appointments, matched primarily by phone
    and falling back to their display name."""
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
        if phone and appt_phone == phone:
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
