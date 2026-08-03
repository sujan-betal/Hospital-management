"""Low-level database query and formatting helpers for the Receptionist module.

Kept separate from the business logic in `receptionist_service.py` so the
service layer stays clean and each helper is reusable.
"""

import json
import random
import uuid
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.invoice_model import Invoice
from src.models.opd_appointment_model import OpdAppointment
from src.models.patient_model import Patient

# ─────────────────────────── Generic ───────────────────────────

def now_timestamp() -> str:
    return datetime.now().strftime("%I:%M %p")


async def _generate_unique_id(db: AsyncSession, model, id_field, prefix: str, digits: int = 4) -> str:
    for _ in range(30):
        value = f"{prefix}-{random.randint(10 ** (digits - 1), (10 ** digits) - 1)}"
        result = await db.execute(select(model.id).where(id_field == value))
        if result.scalar_one_or_none() is None:
            return value
    return f"{prefix}-{uuid.uuid4().hex[:6].upper()}"


# ─────────────────────── Patient Registration ───────────────────────

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


# ─────────────────────── OPD Appointments ───────────────────────

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


async def find_appointment_by_id(db: AsyncSession, appointment_id: str):
    result = await db.execute(
        select(OpdAppointment).where(OpdAppointment.appointment_id == appointment_id)
    )
    return result.scalar_one_or_none()


async def generate_appointment_id(db: AsyncSession) -> str:
    return await _generate_unique_id(db, OpdAppointment, OpdAppointment.appointment_id, "APT")


# ─────────────────────── Billing & Invoices ───────────────────────

def invoice_items_from_db(value) -> list:
    if not value:
        return []
    try:
        parsed = json.loads(value)
        if isinstance(parsed, list):
            return parsed
    except Exception:
        pass
    return []


def invoice_to_dict(invoice: Invoice) -> dict:
    return {
        "id": invoice.id,
        "invoice_id": invoice.invoice_id,
        "patient_name": invoice.patient_name,
        "date": invoice.date,
        "amount": invoice.amount,
        "items": invoice_items_from_db(invoice.items),
        "insurance_status": invoice.insurance_status,
        "payment_status": invoice.payment_status,
        "created_at": invoice.created_at,
        "updated_at": invoice.updated_at,
    }


async def find_invoice_by_id(db: AsyncSession, invoice_id: str):
    result = await db.execute(
        select(Invoice).where(Invoice.invoice_id == invoice_id)
    )
    return result.scalar_one_or_none()


async def generate_invoice_id(db: AsyncSession) -> str:
    return await _generate_unique_id(db, Invoice, Invoice.invoice_id, "INV")
