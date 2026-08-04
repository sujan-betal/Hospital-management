"""Low-level database query and formatting helpers for the Patient module.

Kept separate from the business logic in `patient_service.py` so the
service layer stays clean and each helper is reusable.
"""

import re
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

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
