"""Pydantic request schemas for the Receptionist module.

Front-desk operations — patient registration, OPD appointment booking and
billing entry — are consolidated here so the whole receptionist domain lives
under one schema module.
"""

from pydantic import BaseModel, EmailStr, Field


# ─────────────────────── Receptionist Account ───────────────────────

class ReceptionistCreateRequest(BaseModel):
    user_name: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)


# ─────────────────────── Patient Registration ───────────────────────

class PatientCreateRequest(BaseModel):
    user_name: str = Field(..., min_length=2, max_length=100)
    email: str = Field(default="", max_length=120)
    phone: str = Field(..., min_length=6, max_length=30)
    age: int | None = Field(default=None, ge=0, le=150)
    gender: str | None = Field(default=None, max_length=20)
    insurance_provider: str | None = Field(default=None, max_length=120)


class PatientUpdateRequest(BaseModel):
    user_name: str | None = Field(default=None, min_length=2, max_length=100)
    email: str | None = Field(default=None, max_length=120)
    phone: str | None = Field(default=None, min_length=6, max_length=30)
    age: int | None = Field(default=None, ge=0, le=150)
    gender: str | None = Field(default=None, max_length=20)
    insurance_provider: str | None = Field(default=None, max_length=120)
    status: str | None = Field(default=None, max_length=20)


# ─────────────────────── OPD Appointments ───────────────────────

class AppointmentCreateRequest(BaseModel):
    patient_name: str = Field(..., min_length=2, max_length=100)
    patient_phone: str | None = Field(default=None, max_length=30)
    doctor_name: str = Field(..., min_length=2, max_length=100)
    specialty: str = Field(default="General Medicine", max_length=50)
    date: str = Field(..., min_length=4, max_length=30)
    time: str = Field(..., min_length=3, max_length=30)
    status: str = Field(default="SCHEDULED", max_length=20)


class AppointmentUpdateRequest(BaseModel):
    patient_name: str | None = Field(default=None, min_length=2, max_length=100)
    patient_phone: str | None = Field(default=None, max_length=30)
    doctor_name: str | None = Field(default=None, min_length=2, max_length=100)
    specialty: str | None = Field(default=None, max_length=50)
    date: str | None = Field(default=None, min_length=4, max_length=30)
    time: str | None = Field(default=None, min_length=3, max_length=30)
    status: str | None = Field(default=None, max_length=20)


# ─────────────────────── Billing & Invoices ───────────────────────

class InvoiceItem(BaseModel):
    description: str = Field(..., min_length=1, max_length=200)
    cost: int = Field(..., ge=0)


class InvoiceCreateRequest(BaseModel):
    patient_name: str = Field(..., min_length=2, max_length=100)
    date: str = Field(..., min_length=4, max_length=30)
    items: list[InvoiceItem] = Field(default_factory=list)
    insurance_status: str = Field(default="UNINSURED", max_length=20)
    payment_status: str = Field(default="UNPAID", max_length=20)


class InvoiceUpdateRequest(BaseModel):
    patient_name: str | None = Field(default=None, min_length=2, max_length=100)
    date: str | None = Field(default=None, min_length=4, max_length=30)
    items: list[InvoiceItem] | None = None
    insurance_status: str | None = Field(default=None, max_length=20)
    payment_status: str | None = Field(default=None, max_length=20)
