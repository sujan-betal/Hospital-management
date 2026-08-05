
import uuid as uuid_lib

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.database import get_db
from src.middleware.auth import authorization
from src.modules.receptionist.receptionist_schema import (
    AppointmentCreateRequest,
    AppointmentUpdateRequest,
    InvoiceCreateRequest,
    InvoiceUpdateRequest,
    ReceptionistBedUpdateRequest,
    ReceptionistCreateRequest,
)
from src.modules.receptionist.receptionist_service import (
    create_appointment_service,
    create_invoice_service,
    create_receptionist_service,
    delete_appointment_service,
    delete_invoice_service,
    get_dashboard_service,
    list_appointments_service,
    list_doctors_service,
    list_invoices_service,
    update_appointment_service,
    update_bed_status_service,
    update_invoice_service,
)
from src.modules.hospital.hospital_service import list_beds_service

router = APIRouter(prefix="/api/receptionist", tags=["Receptionist"])

FRONT_DESK_ROLES = ["RECEPTIONIST", "ADMIN", "SUBADMIN"]


@router.get("/beds")
async def list_beds(
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await list_beds_service(db)


@router.put("/beds/{bed_id}")
async def update_bed_status(
    bed_id: str,
    payload: ReceptionistBedUpdateRequest,
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await update_bed_status_service(bed_id, payload, db)


@router.post("/register")
async def create_receptionist(
    payload: ReceptionistCreateRequest,
    admin=Depends(authorization(allowed_roles=["ADMIN", "SUBADMIN"])),
    db: AsyncSession = Depends(get_db),
):
    return await create_receptionist_service(payload, db)


@router.get("/doctors")
async def list_doctors(
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await list_doctors_service(db)


@router.get("/appointments")
async def list_appointments(
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await list_appointments_service(db)


@router.post("/appointments")
async def create_appointment(
    payload: AppointmentCreateRequest,
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await create_appointment_service(payload, db)


@router.put("/appointments/{appointment_id}")
async def update_appointment(
    appointment_id: str,
    payload: AppointmentUpdateRequest,
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await update_appointment_service(appointment_id, payload, db)


@router.delete("/appointments/{appointment_id}")
async def delete_appointment(
    appointment_id: str,
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await delete_appointment_service(appointment_id, db)


@router.get("/invoices")
async def list_invoices(
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await list_invoices_service(db)


@router.post("/invoices")
async def create_invoice(
    payload: InvoiceCreateRequest,
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await create_invoice_service(payload, db)


@router.put("/invoices/{invoice_id}")
async def update_invoice(
    invoice_id: str,
    payload: InvoiceUpdateRequest,
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await update_invoice_service(invoice_id, payload, db)


@router.delete("/invoices/{invoice_id}")
async def delete_invoice(
    invoice_id: str,
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await delete_invoice_service(invoice_id, db)


@router.get("/dashboard")
async def get_dashboard(
    staff=Depends(authorization(allowed_roles=FRONT_DESK_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await get_dashboard_service(db)
