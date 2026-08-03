"""Business logic for the Hospital admin module.

Beds, patient admissions, clinical tasks and hospital settings are all
managed from here. Low-level DB helpers live in `hospital_query.py`.
"""

import json

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.admission_model import Admission
from src.models.bed_model import Bed
from src.models.task_model import ClinicalTask
from src.modules.hospital.hospital_query import (
    admission_to_dict,
    bed_to_dict,
    find_available_bed,
    find_bed_by_id,
    free_bed,
    generate_admission_id,
    generate_task_id,
    get_or_create_settings,
    mark_bed_available,
    now_timestamp,
    settings_to_dict,
    task_to_dict,
)
from src.utils.common_schema import api_response_success, api_response_error
from src.utils.status_code import StatusCode

VALID_BED_STATUSES = {"AVAILABLE", "OCCUPIED", "SANITIZING", "RESERVED"}
VALID_ADMISSION_STATUSES = {"ADMITTED", "SCHEDULED", "DISCHARGED", "CANCELLED"}
VALID_TASK_STATUSES = {"PENDING", "IN-PROGRESS", "COMPLETED"}
VALID_TASK_TYPES = {"NURSING", "LAB-TEST", "PHARMACY", "SANITIZATION"}
VALID_PRIORITIES = {"LOW", "MEDIUM", "HIGH", "EMERGENCY"}


# ─────────────────────────── Beds ───────────────────────────

async def list_beds_service(db: AsyncSession):
    try:
        beds = (
            (await db.execute(select(Bed).order_by(Bed.floor, Bed.bed_id)))
            .scalars()
            .all()
        )
        return api_response_success(
            data=[bed_to_dict(bed) for bed in beds],
            message="Beds fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch beds: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def create_bed_service(payload, db: AsyncSession):
    try:
        existing = (
            await db.execute(select(Bed).where(Bed.bed_id == payload.bed_id))
        ).scalar_one_or_none()
        if existing:
            return api_response_error(
                message="Bed ID already exists",
                status_code=StatusCode.conflict,
            )

        bed = Bed(
            bed_id=payload.bed_id,
            ward=payload.ward,
            status=payload.status.upper() if payload.status else "AVAILABLE",
            price=payload.price,
            floor=payload.floor,
            assigned_nurse=payload.assigned_nurse,
            equipment=json.dumps(payload.equipment or []),
            patient=payload.patient,
        )
        db.add(bed)
        await db.commit()
        await db.refresh(bed)

        return api_response_success(
            data=bed_to_dict(bed),
            message=f"Bed {bed.bed_id} created successfully",
            status_code=StatusCode.create,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to create bed: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_bed_service(bed_id: str, payload, db: AsyncSession):
    try:
        bed = (
            await db.execute(select(Bed).where(Bed.bed_id == bed_id))
        ).scalar_one_or_none()
        if not bed:
            return api_response_error(
                message="Bed not found",
                status_code=StatusCode.notFound,
            )

        if payload.bed_id and payload.bed_id != bed.bed_id:
            conflict = (
                await db.execute(select(Bed).where(Bed.bed_id == payload.bed_id))
            ).scalar_one_or_none()
            if conflict:
                return api_response_error(
                    message="Bed ID already exists",
                    status_code=StatusCode.conflict,
                )
            bed.bed_id = payload.bed_id

        if payload.ward:
            bed.ward = payload.ward
        if payload.status and payload.status.upper() in VALID_BED_STATUSES:
            bed.status = payload.status.upper()
        if payload.price is not None:
            bed.price = payload.price
        if payload.floor is not None:
            bed.floor = payload.floor
        if payload.assigned_nurse is not None:
            bed.assigned_nurse = payload.assigned_nurse
        if payload.equipment is not None:
            bed.equipment = json.dumps(payload.equipment)
        if payload.patient is not None:
            bed.patient = payload.patient

        await db.commit()
        await db.refresh(bed)

        return api_response_success(
            data=bed_to_dict(bed),
            message=f"Bed {bed.bed_id} updated successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update bed: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def delete_bed_service(bed_id: str, db: AsyncSession):
    try:
        bed = (
            await db.execute(select(Bed).where(Bed.bed_id == bed_id))
        ).scalar_one_or_none()
        if not bed:
            return api_response_error(
                message="Bed not found",
                status_code=StatusCode.notFound,
            )

        await db.delete(bed)
        await db.commit()

        return api_response_success(
            data=None,
            message=f"Bed {bed_id} deleted successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to delete bed: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Patient Admissions ───────────────────────

async def _apply_admission_bed(adm: Admission, db: AsyncSession):
    """Assign an occupied bed to an admitted admission."""
    if adm.bed_id in (None, "", "Pending"):
        bed = await find_available_bed(db, adm.ward_type)
        if not bed:
            return "No available bed in the selected ward"
        adm.bed_id = bed.bed_id
        bed.status = "OCCUPIED"
        bed.patient = adm.patient_name
        return None

    bed = await find_bed_by_id(db, adm.bed_id)
    if not bed:
        return f"Bed {adm.bed_id} not found"
    bed.status = "OCCUPIED"
    bed.patient = adm.patient_name
    return None


async def list_admissions_service(db: AsyncSession):
    try:
        admissions = (
            (
                await db.execute(
                    select(Admission).order_by(Admission.created_at.desc())
                )
            )
            .scalars()
            .all()
        )
        return api_response_success(
            data=[admission_to_dict(adm) for adm in admissions],
            message="Admissions fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch admissions: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def create_admission_service(payload, db: AsyncSession):
    try:
        adm = Admission(
            admission_id=await generate_admission_id(db),
            patient_name=payload.patient_name,
            patient_age=payload.patient_age,
            patient_gender=payload.patient_gender,
            ward_type=payload.ward_type,
            bed_id=payload.bed_id or "Pending",
            admit_date=payload.admit_date,
            discharge_date=payload.discharge_date,
            billing_amount=payload.billing_amount,
            status=payload.status.upper() if payload.status else "ADMITTED",
            insurance_status=payload.insurance_status.upper()
            if payload.insurance_status
            else "COVERED",
            patient_email=payload.patient_email,
            patient_phone=payload.patient_phone,
        )
        db.add(adm)
        await db.flush()

        if adm.status == "ADMITTED":
            error = await _apply_admission_bed(adm, db)
            if error:
                await db.rollback()
                return api_response_error(
                    message=error,
                    status_code=StatusCode.badRequest,
                )

        await db.commit()
        await db.refresh(adm)

        return api_response_success(
            data=admission_to_dict(adm),
            message=f"Admission {adm.admission_id} created successfully",
            status_code=StatusCode.create,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to create admission: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_admission_service(admission_id: str, payload, db: AsyncSession):
    try:
        adm = (
            await db.execute(
                select(Admission).where(Admission.admission_id == admission_id)
            )
        ).scalar_one_or_none()
        if not adm:
            return api_response_error(
                message="Admission not found",
                status_code=StatusCode.notFound,
            )

        prev_status = adm.status
        prev_bed_id = adm.bed_id

        if payload.patient_name is not None:
            adm.patient_name = payload.patient_name
        if payload.patient_age is not None:
            adm.patient_age = payload.patient_age
        if payload.patient_gender is not None:
            adm.patient_gender = payload.patient_gender
        if payload.ward_type is not None:
            adm.ward_type = payload.ward_type
        if payload.bed_id is not None:
            adm.bed_id = payload.bed_id
        if payload.admit_date is not None:
            adm.admit_date = payload.admit_date
        if payload.discharge_date is not None:
            adm.discharge_date = payload.discharge_date
        if payload.billing_amount is not None:
            adm.billing_amount = payload.billing_amount
        if payload.status is not None and payload.status.upper() in VALID_ADMISSION_STATUSES:
            adm.status = payload.status.upper()
        if payload.insurance_status is not None:
            adm.insurance_status = payload.insurance_status.upper()
        if payload.patient_email is not None:
            adm.patient_email = payload.patient_email
        if payload.patient_phone is not None:
            adm.patient_phone = payload.patient_phone

        if adm.status == "ADMITTED":
            error = await _apply_admission_bed(adm, db)
            if error:
                await db.rollback()
                return api_response_error(
                    message=error,
                    status_code=StatusCode.badRequest,
                )
            if (
                prev_bed_id
                and prev_bed_id != "Pending"
                and prev_bed_id != adm.bed_id
            ):
                await free_bed(db, prev_bed_id, "AVAILABLE")

        elif adm.status == "DISCHARGED":
            if prev_bed_id and prev_bed_id != "Pending":
                await free_bed(db, prev_bed_id, "SANITIZING")
                db.add(
                    ClinicalTask(
                        task_id=await generate_task_id(db),
                        bed_id=prev_bed_id,
                        task_description=(
                            "Post-discharge sanitization and sterile linen replacement"
                        ),
                        priority="MEDIUM",
                        assigned_to="Nursing Staff",
                        status="PENDING",
                        task_type="SANITIZATION",
                        timestamp=now_timestamp(),
                    )
                )

        elif adm.status == "CANCELLED":
            if prev_bed_id and prev_bed_id != "Pending":
                await free_bed(db, prev_bed_id, "AVAILABLE")

        await db.commit()
        await db.refresh(adm)

        return api_response_success(
            data=admission_to_dict(adm),
            message=f"Admission {adm.admission_id} updated successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update admission: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def delete_admission_service(admission_id: str, db: AsyncSession):
    try:
        adm = (
            await db.execute(
                select(Admission).where(Admission.admission_id == admission_id)
            )
        ).scalar_one_or_none()
        if not adm:
            return api_response_error(
                message="Admission not found",
                status_code=StatusCode.notFound,
            )

        if adm.bed_id and adm.bed_id != "Pending":
            await free_bed(db, adm.bed_id, "AVAILABLE")

        await db.delete(adm)
        await db.commit()

        return api_response_success(
            data=None,
            message=f"Admission {admission_id} deleted successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to delete admission: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Clinical Tasks ───────────────────────

async def list_tasks_service(db: AsyncSession):
    try:
        tasks = (
            (
                await db.execute(
                    select(ClinicalTask).order_by(ClinicalTask.created_at.desc())
                )
            )
            .scalars()
            .all()
        )
        return api_response_success(
            data=[task_to_dict(task) for task in tasks],
            message="Tasks fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch tasks: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def create_task_service(payload, db: AsyncSession):
    try:
        task = ClinicalTask(
            task_id=await generate_task_id(db),
            bed_id=payload.bed_id,
            task_description=payload.task_description,
            priority=payload.priority.upper() if payload.priority else "MEDIUM",
            assigned_to=payload.assigned_to,
            status=payload.status.upper() if payload.status else "PENDING",
            task_type=payload.task_type.upper() if payload.task_type else "NURSING",
            timestamp=payload.timestamp or now_timestamp(),
        )
        db.add(task)
        await db.commit()
        await db.refresh(task)

        return api_response_success(
            data=task_to_dict(task),
            message=f"Task {task.task_id} dispatched successfully",
            status_code=StatusCode.create,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to create task: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_task_service(task_id: str, payload, db: AsyncSession):
    try:
        task = (
            await db.execute(select(ClinicalTask).where(ClinicalTask.task_id == task_id))
        ).scalar_one_or_none()
        if not task:
            return api_response_error(
                message="Task not found",
                status_code=StatusCode.notFound,
            )

        prev_status = task.status

        if payload.bed_id is not None:
            task.bed_id = payload.bed_id
        if payload.task_description is not None:
            task.task_description = payload.task_description
        if payload.priority is not None and payload.priority.upper() in VALID_PRIORITIES:
            task.priority = payload.priority.upper()
        if payload.assigned_to is not None:
            task.assigned_to = payload.assigned_to
        if payload.status is not None and payload.status.upper() in VALID_TASK_STATUSES:
            task.status = payload.status.upper()
        if payload.task_type is not None and payload.task_type.upper() in VALID_TASK_TYPES:
            task.task_type = payload.task_type.upper()
        if payload.timestamp is not None:
            task.timestamp = payload.timestamp

        if (
            task.status == "COMPLETED"
            and task.task_type == "SANITIZATION"
            and prev_status != "COMPLETED"
        ):
            await mark_bed_available(db, task.bed_id)

        await db.commit()
        await db.refresh(task)

        return api_response_success(
            data=task_to_dict(task),
            message=f"Task {task.task_id} updated successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update task: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def delete_task_service(task_id: str, db: AsyncSession):
    try:
        task = (
            await db.execute(select(ClinicalTask).where(ClinicalTask.task_id == task_id))
        ).scalar_one_or_none()
        if not task:
            return api_response_error(
                message="Task not found",
                status_code=StatusCode.notFound,
            )

        await db.delete(task)
        await db.commit()

        return api_response_success(
            data=None,
            message=f"Task {task_id} deleted successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to delete task: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Hospital Settings ───────────────────────

async def get_settings_service(db: AsyncSession):
    try:
        setting = await get_or_create_settings(db)
        return api_response_success(
            data=settings_to_dict(setting),
            message="Hospital settings fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch settings: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_settings_service(payload, db: AsyncSession):
    try:
        setting = await get_or_create_settings(db)
        for field in ["hospital_name", "address", "currency", "copay_rate",
                      "emergency_markup", "auto_telemetry", "sanitation_interval",
                      "auto_dirty"]:
            value = getattr(payload, field, None)
            if value is not None:
                setattr(setting, field, value)

        await db.commit()
        await db.refresh(setting)

        return api_response_success(
            data=settings_to_dict(setting),
            message="Hospital settings updated successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update settings: {str(e)}",
            status_code=StatusCode.internalServerError,
        )
