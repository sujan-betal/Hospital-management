
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.database import get_db
from src.middleware.auth import authorization
from src.modules.doctor.doctor_schema import (
    DoctorCreateRequest,
    DoctorForgotPasswordRequest,
    DoctorLoginRequest,
    DoctorResetPasswordRequest,
)
from src.modules.doctor.doctor_service import (
    create_doctor_service,
    forgot_password_service,
    login_doctor_service,
    reset_password_service,
)

router = APIRouter(prefix="/api", tags=["Doctor"])


@router.post("/admin/doctors")
async def create_doctor(
    payload: DoctorCreateRequest,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await create_doctor_service(payload, admin.user_id, db)


@router.post("/doctor/login")
async def login_doctor(
    payload: DoctorLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    return await login_doctor_service(payload, db)


@router.post("/doctor/forgot-password")
async def forgot_doctor_password(
    payload: DoctorForgotPasswordRequest,
    db: AsyncSession = Depends(get_db),
):
    return await forgot_password_service(payload, db)


@router.post("/doctor/reset-password")
async def reset_doctor_password(
    payload: DoctorResetPasswordRequest,
    db: AsyncSession = Depends(get_db),
):
    return await reset_password_service(payload, db)
