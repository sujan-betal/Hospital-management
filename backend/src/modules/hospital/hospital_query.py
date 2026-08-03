"""Low-level database query and formatting helpers for the Hospital module.

Kept separate from the business logic in `hospital_service.py` so the
service layer stays clean and each helper is reusable.
"""

import json
import random
import uuid
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.admission_model import Admission
from src.models.bed_model import Bed
from src.models.hospital_setting_model import HospitalSetting
from src.models.task_model import ClinicalTask

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


# ─────────────────────────── Beds ───────────────────────────

def equipment_from_db(value) -> list:
    if not value:
        return []
    try:
        parsed = json.loads(value)
        if isinstance(parsed, list):
            return parsed
    except Exception:
        pass
    return [item.strip() for item in str(value).split(",") if item.strip()]


def bed_to_dict(bed: Bed) -> dict:
    return {
        "id": bed.id,
        "bed_id": bed.bed_id,
        "ward": bed.ward,
        "status": bed.status,
        "price": bed.price,
        "floor": bed.floor,
        "assigned_nurse": bed.assigned_nurse,
        "equipment": equipment_from_db(bed.equipment),
        "patient": bed.patient,
        "created_at": bed.created_at,
        "updated_at": bed.updated_at,
    }


async def find_bed_by_id(db: AsyncSession, bed_id: str):
    if not bed_id or bed_id == "Pending":
        return None
    result = await db.execute(select(Bed).where(Bed.bed_id == bed_id))
    return result.scalar_one_or_none()


async def find_available_bed(db: AsyncSession, ward_type: str):
    result = await db.execute(
        select(Bed)
        .where(Bed.ward == ward_type, Bed.status == "AVAILABLE")
        .order_by(Bed.id)
        .limit(1)
    )
    return result.scalar_one_or_none()


async def free_bed(db: AsyncSession, bed_id: str, next_status: str = "AVAILABLE"):
    bed = await find_bed_by_id(db, bed_id)
    if bed:
        bed.status = next_status
        bed.patient = None


# ─────────────────────── Patient Admissions ───────────────────────

def admission_to_dict(adm: Admission) -> dict:
    return {
        "id": adm.id,
        "admission_id": adm.admission_id,
        "patient_name": adm.patient_name,
        "patient_age": adm.patient_age,
        "patient_gender": adm.patient_gender,
        "ward_type": adm.ward_type,
        "bed_id": adm.bed_id or "Pending",
        "admit_date": adm.admit_date,
        "discharge_date": adm.discharge_date,
        "billing_amount": adm.billing_amount,
        "status": adm.status,
        "insurance_status": adm.insurance_status,
        "patient_email": adm.patient_email,
        "patient_phone": adm.patient_phone,
        "created_at": adm.created_at,
        "updated_at": adm.updated_at,
    }


async def generate_admission_id(db: AsyncSession) -> str:
    return await _generate_unique_id(db, Admission, Admission.admission_id, "ADM")


# ─────────────────────── Clinical Tasks ───────────────────────

def task_to_dict(task: ClinicalTask) -> dict:
    return {
        "id": task.id,
        "task_id": task.task_id,
        "bed_id": task.bed_id,
        "task_description": task.task_description,
        "priority": task.priority,
        "assigned_to": task.assigned_to,
        "status": task.status,
        "task_type": task.task_type,
        "timestamp": task.timestamp,
        "created_at": task.created_at,
        "updated_at": task.updated_at,
    }


async def generate_task_id(db: AsyncSession) -> str:
    return await _generate_unique_id(db, ClinicalTask, ClinicalTask.task_id, "TSK")


async def mark_bed_available(db: AsyncSession, bed_id: str):
    if not bed_id or bed_id in ("Pending", "—"):
        return
    bed = await find_bed_by_id(db, bed_id)
    if bed and bed.status == "SANITIZING":
        bed.status = "AVAILABLE"
        bed.patient = None


# ─────────────────────── Hospital Settings ───────────────────────

DEFAULT_SETTINGS = {
    "hospital_name": "AURA Medical Center & ICU",
    "address": "456 Care Boulevard, Medical District, SF 94102",
    "currency": "INR (Rs.)",
    "copay_rate": 10,
    "emergency_markup": 25,
    "auto_telemetry": True,
    "sanitation_interval": 12,
    "auto_dirty": True,
}

SETTINGS_UPDATABLE_FIELDS = [
    "hospital_name",
    "address",
    "currency",
    "copay_rate",
    "emergency_markup",
    "auto_telemetry",
    "sanitation_interval",
    "auto_dirty",
]


def settings_to_dict(setting: HospitalSetting) -> dict:
    return {
        "id": setting.id,
        "hospital_name": setting.hospital_name,
        "address": setting.address,
        "currency": setting.currency,
        "copay_rate": setting.copay_rate,
        "emergency_markup": setting.emergency_markup,
        "auto_telemetry": setting.auto_telemetry,
        "sanitation_interval": setting.sanitation_interval,
        "auto_dirty": setting.auto_dirty,
        "created_at": setting.created_at,
        "updated_at": setting.updated_at,
    }


async def get_or_create_settings(db: AsyncSession) -> HospitalSetting:
    result = await db.execute(
        select(HospitalSetting).order_by(HospitalSetting.id).limit(1)
    )
    setting = result.scalar_one_or_none()
    if not setting:
        setting = HospitalSetting(**DEFAULT_SETTINGS)
        db.add(setting)
        await db.commit()
        await db.refresh(setting)
    return setting
