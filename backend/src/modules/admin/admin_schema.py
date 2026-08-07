from pydantic import BaseModel, EmailStr, Field

class AdminRegisterRequest(BaseModel):
    user_name: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)

class AdminLoginRequest(BaseModel):
    # Accepts either an email address or a username.
    email: str = Field(..., min_length=3, max_length=120)
    password: str = Field(..., min_length=6)

class SubAdminCreateRequest(BaseModel):
    user_name: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    # Optional for API compatibility — sub-admins set their password via the
    # emailed reset link (the provided value is ignored).
    # password: str | None = Field(default=None, min_length=6)
    permissions: list[str] = Field(default_factory=list)

class PermissionAssignRequest(BaseModel):
    admin_id: int = Field(..., gt=0)
    permissions: list[str] = Field(..., min_length=1)

class StaffUpdateRequest(BaseModel):
    user_name: str | None = Field(default=None, min_length=3, max_length=50)
    email: EmailStr | None = None
    phone: str | None = Field(default=None, max_length=20)
    department: str | None = Field(default=None, max_length=100)
    status: str | None = None
