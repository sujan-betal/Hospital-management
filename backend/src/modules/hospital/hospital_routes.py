from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.database import get_db
from src.middleware.auth import authorization
from src.modules.hospital.hospital_schema import (
    AdmissionCreateRequest,
    AdmissionUpdateRequest,
    BedCreateRequest,
    BedUpdateRequest,
    SettingsUpdateRequest,
    TaskCreateRequest,
    TaskUpdateRequest,
)
from src.modules.hospital.hospital_service import (
    create_admission_service,
    create_bed_service,
    create_task_service,
    delete_admission_service,
    delete_bed_service,
    delete_task_service,
    get_revenue_service,
    get_settings_service,
    list_admissions_service,
    list_beds_service,
    list_tasks_service,
    update_admission_service,
    update_bed_service,
    update_settings_service,
    update_task_service,
)

router = APIRouter(prefix="/api/admin", tags=["Hospital"])

@router.get("/beds")
async def list_beds(
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await list_beds_service(db)

@router.post("/beds")
async def create_bed(
    payload: BedCreateRequest,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await create_bed_service(payload, db)

@router.put("/beds/{bed_id}")
async def update_bed(
    bed_id: str,
    payload: BedUpdateRequest,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await update_bed_service(bed_id, payload, db)

@router.delete("/beds/{bed_id}")
async def delete_bed(
    bed_id: str,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await delete_bed_service(bed_id, db)


@router.get("/admissions")
async def list_admissions(
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await list_admissions_service(db)

@router.post("/admissions")
async def create_admission(
    payload: AdmissionCreateRequest,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await create_admission_service(payload, db)

@router.put("/admissions/{admission_id}")
async def update_admission(
    admission_id: str,
    payload: AdmissionUpdateRequest,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await update_admission_service(admission_id, payload, db)

@router.delete("/admissions/{admission_id}")
async def delete_admission(
    admission_id: str,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await delete_admission_service(admission_id, db)


@router.get("/tasks")
async def list_tasks(
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await list_tasks_service(db)

@router.post("/tasks")
async def create_task(
    payload: TaskCreateRequest,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await create_task_service(payload, db)

@router.put("/tasks/{task_id}")
async def update_task(
    task_id: str,
    payload: TaskUpdateRequest,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await update_task_service(task_id, payload, db)

@router.delete("/tasks/{task_id}")
async def delete_task(
    task_id: str,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await delete_task_service(task_id, db)


@router.get("/settings")
async def get_settings(
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await get_settings_service(db)

@router.put("/settings")
async def update_settings(
    payload: SettingsUpdateRequest,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await update_settings_service(payload, db)


@router.get("/revenue")
async def get_revenue(
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await get_revenue_service(db)
