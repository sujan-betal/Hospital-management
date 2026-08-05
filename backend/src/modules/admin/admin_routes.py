
import uuid as uuid_lib

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.database import get_db
from src.middleware.auth import authorization
from src.modules.admin.admin_schema import (
    AdminLoginRequest,
    AdminRegisterRequest,
    PermissionAssignRequest,
    StaffUpdateRequest,
    SubAdminCreateRequest,
)
from src.modules.admin.admin_service import (
    assign_permissions_service,
    create_subadmin_service,
    delete_staff_service,
    list_doctors_service,
    list_permissions_service,
    list_staff_service,
    login_staff_service,
    register_admin_service,
    update_staff_service,
)

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
    return await login_staff_service(payload, db)

@router.post("/subadmins")
async def create_subadmin(
    payload: SubAdminCreateRequest,
    admin=Depends(
        authorization(
            allowed_roles=["ADMIN", "SUBADMIN"],
            required_permissions=["SUBADMIN_CREATE"],
        )
    ),
    db: AsyncSession = Depends(get_db),
):
    return await create_subadmin_service(payload, admin.user_id, db)

@router.put("/permissions")
async def assign_permissions(
    payload: PermissionAssignRequest,
    admin=Depends(
        authorization(
            allowed_roles=["ADMIN", "SUBADMIN"],
            required_permissions=["SUBADMIN_CREATE"],
        )
    ),
    db: AsyncSession = Depends(get_db),
):
    return await assign_permissions_service(payload, db)

@router.get("/permissions")
async def list_permissions(
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await list_permissions_service(db)

@router.get("/doctors")
async def list_doctors(
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await list_doctors_service(db)


@router.get("/staff")
async def list_staff(
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await list_staff_service(db)

@router.put("/staff/{user_id}")
async def update_staff(
    user_id: uuid_lib.UUID,
    payload: StaffUpdateRequest,
    admin=Depends(
        authorization(
            allowed_roles=["ADMIN", "SUBADMIN"],
            required_permissions=["STAFF_MANAGE"],
        )
    ),
    db: AsyncSession = Depends(get_db),
):
    return await update_staff_service(user_id, payload, db)

@router.delete("/staff/{user_id}")
async def delete_staff(
    user_id: uuid_lib.UUID,
    admin=Depends(
        authorization(
            allowed_roles=["ADMIN", "SUBADMIN"],
            required_permissions=["STAFF_MANAGE"],
        )
    ),
    db: AsyncSession = Depends(get_db),
):
    return await delete_staff_service(user_id, admin, db)
