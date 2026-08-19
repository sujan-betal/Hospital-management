"""Pydantic request schemas for the Hospital admin module.

Consolidated here so the whole hospital domain (beds, admissions,
clinical tasks and hospital settings) lives under one schema module.
"""

from pydantic import BaseModel, Field


# ─────────────────────────── Beds ───────────────────────────

class BedCreateRequest(BaseModel):
    bed_id: str = Field(..., min_length=2, max_length=50)
    ward: str = Field(..., min_length=2, max_length=50)
    status: str = Field(default="AVAILABLE", max_length=20)
    price: int = Field(default=0, ge=0)
    floor: int = Field(default=1, ge=0)
    assigned_nurse: str | None = Field(default=None, max_length=100)
    equipment: list[str] = Field(default_factory=list)
    patient: str | None = Field(default=None, max_length=100)


class BedUpdateRequest(BaseModel):
    bed_id: str | None = Field(default=None, min_length=2, max_length=50)
    ward: str | None = Field(default=None, min_length=2, max_length=50)
    status: str | None = Field(default=None, max_length=20)
    price: int | None = Field(default=None, ge=0)
    floor: int | None = Field(default=None, ge=0)
    assigned_nurse: str | None = Field(default=None, max_length=100)
    equipment: list[str] | None = None
    patient: str | None = Field(default=None, max_length=100)


# ─────────────────────── Patient Admissions ───────────────────────

class AdmissionCreateRequest(BaseModel):
    patient_name: str = Field(..., min_length=2, max_length=100)
    patient_age: int = Field(..., ge=0, le=150)
    patient_gender: str = Field(default="Male", max_length=20)
    ward_type: str = Field(default="General Ward", max_length=50)
    bed_id: str | None = Field(default="Pending", max_length=50)
    admit_date: str = Field(..., min_length=4, max_length=30)
    discharge_date: str | None = Field(default=None, max_length=30)
    billing_amount: int = Field(default=0, ge=0)
    status: str = Field(default="ADMITTED", max_length=20)
    insurance_status: str = Field(default="COVERED", max_length=20)
    patient_email: str = Field(default="", max_length=120)
    patient_phone: str = Field(default="", max_length=30)


class AdmissionUpdateRequest(BaseModel):
    patient_name: str | None = Field(default=None, min_length=2, max_length=100)
    patient_age: int | None = Field(default=None, ge=0, le=150)
    patient_gender: str | None = Field(default=None, max_length=20)
    ward_type: str | None = Field(default=None, max_length=50)
    bed_id: str | None = Field(default=None, max_length=50)
    admit_date: str | None = Field(default=None, min_length=4, max_length=30)
    discharge_date: str | None = Field(default=None, max_length=30)
    billing_amount: int | None = Field(default=None, ge=0)
    status: str | None = Field(default=None, max_length=20)
    insurance_status: str | None = Field(default=None, max_length=20)
    patient_email: str | None = Field(default=None, max_length=120)
    patient_phone: str | None = Field(default=None, max_length=30)


# ─────────────────────── Clinical Tasks ───────────────────────

class TaskCreateRequest(BaseModel):
    bed_id: str = Field(..., min_length=1, max_length=50)
    task_description: str = Field(..., min_length=3, max_length=500)
    priority: str = Field(default="MEDIUM", max_length=20)
    assigned_to: str = Field(..., min_length=2, max_length=100)
    status: str = Field(default="PENDING", max_length=20)
    task_type: str = Field(default="NURSING", max_length=20)
    timestamp: str | None = Field(default=None, max_length=30)


class TaskUpdateRequest(BaseModel):
    bed_id: str | None = Field(default=None, max_length=50)
    task_description: str | None = Field(default=None, min_length=3, max_length=500)
    priority: str | None = Field(default=None, max_length=20)
    assigned_to: str | None = Field(default=None, max_length=100)
    status: str | None = Field(default=None, max_length=20)
    task_type: str | None = Field(default=None, max_length=20)
    timestamp: str | None = Field(default=None, max_length=30)


# ─────────────────────── Hospital Settings ───────────────────────

class SettingsUpdateRequest(BaseModel):
    hospital_name: str | None = Field(default=None, min_length=2, max_length=150)
    address: str | None = Field(default=None, max_length=300)
    currency: str | None = Field(default=None, max_length=30)
    copay_rate: int | None = Field(default=None, ge=0, le=100)
    emergency_markup: int | None = Field(default=None, ge=0, le=500)
    doctor_share_percent: int | None = Field(default=None, ge=0, le=100)
    auto_telemetry: bool | None = None
    sanitation_interval: int | None = Field(default=None, ge=1, le=168)
    auto_dirty: bool | None = None
