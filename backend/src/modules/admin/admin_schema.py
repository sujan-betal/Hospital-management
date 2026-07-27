from pydantic import BaseModel, EmailStr, Field

class AdminRegisterRequest(BaseModel):
    user_name: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)

class AdminLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)
