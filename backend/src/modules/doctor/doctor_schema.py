from pydantic import BaseModel, EmailStr, Field

class DoctorCreateRequest(BaseModel):
    user_name: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    phone: str | None = Field(default=None, max_length=20)
    department: str | None = Field(default=None, max_length=100)

class DoctorLoginRequest(BaseModel):
    # Accepts either an email address or a username.
    email: str = Field(..., min_length=3, max_length=120)
    password: str = Field(..., min_length=6)

class DoctorForgotPasswordRequest(BaseModel):
    # Accepts either an email address or a username.
    email: str = Field(..., min_length=3, max_length=120)

class DoctorResetPasswordRequest(BaseModel):
    token: str = Field(..., min_length=10)
    new_password: str = Field(..., min_length=6)
