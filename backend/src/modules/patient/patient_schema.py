from pydantic import BaseModel, EmailStr, Field


class PatientCreateRequest(BaseModel):
    """Staff/admin creates a patient. Patients log in via phone OTP, so no
    password is set here."""
    user_name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr | None = None
    phone: str = Field(..., min_length=6, max_length=30)
    age: int | None = Field(default=None, ge=0, le=150)
    gender: str | None = Field(default=None, max_length=20)
    insurance_provider: str | None = Field(default=None, max_length=120)


class PatientOtpSendRequest(BaseModel):
    phone: str = Field(..., min_length=6, max_length=30)


class PatientOtpVerifyRequest(BaseModel):
    phone: str = Field(..., min_length=6, max_length=30)
    otp: str = Field(..., min_length=4, max_length=8)


class PatientUpdateRequest(BaseModel):
    user_name: str | None = Field(default=None, min_length=2, max_length=100)
    email: EmailStr | None = None
    phone: str | None = Field(default=None, min_length=6, max_length=30)
    age: int | None = Field(default=None, ge=0, le=150)
    gender: str | None = Field(default=None, max_length=20)
    insurance_provider: str | None = Field(default=None, max_length=120)
    status: str | None = Field(default=None, max_length=20)


class PatientAppointmentCreateRequest(BaseModel):
    """Self-service OPD appointment booking. Patient identity (name/phone)
    is taken from the authenticated account, not trusted client input."""
    doctor_name: str = Field(..., min_length=2, max_length=100)
    specialty: str = Field(default="General Medicine", max_length=50)
    date: str = Field(..., min_length=4, max_length=30)
    time: str = Field(..., min_length=3, max_length=30)
