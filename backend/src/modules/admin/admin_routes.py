
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.database import get_db
from src.modules.admin.admin_schema import AdminRegisterRequest, AdminLoginRequest
from src.modules.admin.admin_service import register_admin_service, login_admin_service

router = APIRouter(prefix="/api/admin", tags=["Admin Authentication"])

@router.post("/register")
async def register_admin(
    payload: AdminRegisterRequest,
    db: AsyncSession = Depends(get_db)
):
    return await register_admin_service(payload, db)

@router.post("/login")
async def login_admin(
    payload: AdminLoginRequest,
    db: AsyncSession = Depends(get_db)
):
    return await login_admin_service(payload, db)
