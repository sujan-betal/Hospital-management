"""Business logic for the Receptionist module.

Front-desk operations — OPD appointment booking and billing entry — are
managed from here. Low-level DB helpers live in `receptionist_query.py`.
"""

import json
import os
from datetime import date

from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.admission_model import Admission
from src.models.bed_model import Bed
from src.models.doctor_model import Doctor
from src.models.invoice_model import Invoice
from src.models.opd_appointment_model import OpdAppointment
from src.models.patient_model import Patient
from src.models.receptionist_model import Receptionist
from src.models.task_model import ClinicalTask
from src.modules.receptionist.receptionist_query import (
    appointment_to_dict,
    find_appointment_by_id,
    find_invoice_by_id,
    generate_appointment_id,
    generate_invoice_id,
    invoice_to_dict,
)
from src.modules.hospital.hospital_query import bed_to_dict, find_bed_by_id
from src.modules.hospital.hospital_service import VALID_BED_STATUSES
from src.utils.common_schema import api_response_success, api_response_error
from src.utils.email import send_password_reset_email
from src.utils.reset import (
    RESET_TOKEN_EXPIRE_MINUTES,
    build_reset_link,
    create_reset_token,
)
from src.utils.security import get_password_hash
from src.utils.status_code import StatusCode

VALID_APPOINTMENT_STATUSES = {"SCHEDULED", "CHECKED-IN", "COMPLETED", "CANCELLED"}
VALID_INSURANCE_STATUSES = {"COVERED", "UNINSURED", "PENDING"}
VALID_PAYMENT_STATUSES = {"PAID", "UNPAID"}


def _today() -> str:
    return date.today().isoformat()


# ─────────────────────── Receptionist Account ───────────────────────

async def create_receptionist_service(payload, db: AsyncSession):
    """Admin-only: create a receptionist account and email a password-set link."""
    try:
        query = select(Receptionist).where(
            or_(
                Receptionist.email == payload.email,
                Receptionist.user_name == payload.user_name,
            )
        )
        result = await db.execute(query)
        existing = result.scalar_one_or_none()

        if existing:
            message = (
                "Email already registered"
                if existing.email == payload.email
                else "Username already exists"
            )
            return api_response_error(
                message=message,
                status_code=StatusCode.conflict,
            )

        # No usable password yet: the receptionist must set one via the
        # emailed link, mirroring the doctor account flow.
        receptionist = Receptionist(
            user_name=payload.user_name,
            email=payload.email,
            password=get_password_hash(os.urandom(24).hex()),
            role="RECEPTIONIST",
            status="ACTIVE",
            is_reset=True,
        )
        db.add(receptionist)
        await db.commit()
        await db.refresh(receptionist)

        # user_id is only assigned after commit, so build the reset token now
        # to avoid embedding "None" as the UUID in the emailed link.
        reset_token = create_reset_token(receptionist.user_id, "RECEPTIONIST")
        receptionist.token = reset_token
        await db.commit()
        await db.refresh(receptionist)

        reset_link = build_reset_link(reset_token)
        delivered, email_reason = send_password_reset_email(
            to_email=receptionist.email,
            full_name=receptionist.user_name,
            reset_link=reset_link,
            reset_minutes=RESET_TOKEN_EXPIRE_MINUTES,
            login_email=receptionist.email,
            login_username=receptionist.user_name,
        )

        message = (
            "Receptionist account created. A password-set email has been sent to "
            f"{receptionist.email}."
            if delivered
            else f"Receptionist account created, but the password-set email could not "
                 f"be sent to {receptionist.email}. {email_reason}"
        )

        return api_response_success(
            data={
                "id": receptionist.id,
                "user_id": str(receptionist.user_id),
                "user_name": receptionist.user_name,
                "email": receptionist.email,
                "role": receptionist.role,
                "status": receptionist.status,
            },
            message=message,
            status_code=StatusCode.create,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to create receptionist: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Ward / Bed Management ───────────────────────

async def update_bed_status_service(bed_id: str, payload, db: AsyncSession):
    """Front-desk bed action: book (OCCUPIED/RESERVED) or release (AVAILABLE).

    Receptionists can only change a bed's status and the patient assigned to
    it — ward, price, floor and equipment remain admin-managed. Any update is
    written to the same `beds` table the admin dashboard reads, so admin sees
    the receptionist's changes immediately.
    """
    try:
        bed = await find_bed_by_id(db, bed_id)
        if not bed:
            return api_response_error(
                message="Bed not found",
                status_code=StatusCode.notFound,
            )

        if payload.status and payload.status.upper() in VALID_BED_STATUSES:
            bed.status = payload.status.upper()
        if payload.patient is not None:
            bed.patient = payload.patient

        if bed.status == "AVAILABLE":
            bed.patient = None

        await db.commit()
        await db.refresh(bed)

        return api_response_success(
            data=bed_to_dict(bed),
            message=f"Bed {bed.bed_id} marked {bed.status}",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update bed: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Doctors (booking reference) ───────────────────────

async def list_doctors_service(db: AsyncSession):
    try:
        doctors = (
            (await db.execute(
                select(Doctor).where(Doctor.status == "ACTIVE")
            ))
            .scalars()
            .all()
        )
        records = [
            {
                "user_id": str(doc.user_id),
                "name": doc.user_name,
                "specialty": doc.department or "General Medicine",
                "department": doc.department,
                "email": doc.email,
                "phone": doc.phone,
                "rating": round(float(doc.rating), 1) if doc.rating is not None else 4.0,
                "review_count": doc.review_count or 0,
                "experience_years": doc.experience_years or 0,
                "is_top_rated": (doc.rating or 4.0) >= 4.5,
            }
            for doc in doctors
        ]
        return api_response_success(
            data=records,
            message="Doctors fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch doctors: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── OPD Appointments ───────────────────────

async def list_appointments_service(db: AsyncSession):
    try:
        appointments = (
            (
                await db.execute(
                    select(OpdAppointment).order_by(
                        OpdAppointment.date.desc(), OpdAppointment.id.desc()
                    )
                )
            )
            .scalars()
            .all()
        )
        return api_response_success(
            data=[appointment_to_dict(a) for a in appointments],
            message="Appointments fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch appointments: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def create_appointment_service(payload, db: AsyncSession):
    try:
        existing_slot = (
            (
                await db.execute(
                    select(OpdAppointment).where(
                        OpdAppointment.doctor_name == payload.doctor_name,
                        OpdAppointment.date == payload.date,
                        OpdAppointment.time == payload.time,
                        OpdAppointment.status != "CANCELLED",
                    )
                )
            )
            .scalars()
            .first()
        )
        if existing_slot:
            return api_response_error(
                message=(
                    f"This time slot is already booked for {payload.doctor_name} "
                    f"on {payload.date}. Please pick another time."
                ),
                status_code=StatusCode.conflict,
            )

        appt = OpdAppointment(
            appointment_id=await generate_appointment_id(db),
            patient_name=payload.patient_name,
            patient_phone=payload.patient_phone,
            doctor_name=payload.doctor_name,
            specialty=payload.specialty,
            date=payload.date,
            time=payload.time,
            status=payload.status.upper() if payload.status else "SCHEDULED",
        )
        db.add(appt)
        try:
            await db.commit()
        except IntegrityError:
            await db.rollback()
            return api_response_error(
                message=(
                    f"This time slot was just booked for {payload.doctor_name} "
                    f"on {payload.date}. Please pick another time."
                ),
                status_code=StatusCode.conflict,
            )
        await db.refresh(appt)

        return api_response_success(
            data=appointment_to_dict(appt),
            message=f"Appointment {appt.appointment_id} booked successfully",
            status_code=StatusCode.create,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to book appointment: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_appointment_service(appointment_id: str, payload, db: AsyncSession):
    try:
        appt = await find_appointment_by_id(db, appointment_id)
        if not appt:
            return api_response_error(
                message="Appointment not found",
                status_code=StatusCode.notFound,
            )

        new_doctor = payload.doctor_name if payload.doctor_name is not None else appt.doctor_name
        new_date = payload.date if payload.date is not None else appt.date
        new_time = payload.time if payload.time is not None else appt.time
        if (
            payload.doctor_name is not None
            or payload.date is not None
            or payload.time is not None
        ):
            conflict = (
                (
                    await db.execute(
                        select(OpdAppointment).where(
                            OpdAppointment.doctor_name == new_doctor,
                            OpdAppointment.date == new_date,
                            OpdAppointment.time == new_time,
                            OpdAppointment.status != "CANCELLED",
                            OpdAppointment.appointment_id != appointment_id,
                        )
                    )
                )
                .scalars()
                .first()
            )
            if conflict:
                return api_response_error(
                    message=(
                        f"This time slot is already booked for {new_doctor} "
                        f"on {new_date}. Please pick another time."
                    ),
                    status_code=StatusCode.conflict,
                )

        if payload.patient_name is not None:
            appt.patient_name = payload.patient_name
        if payload.patient_phone is not None:
            appt.patient_phone = payload.patient_phone
        if payload.doctor_name is not None:
            appt.doctor_name = payload.doctor_name
        if payload.specialty is not None:
            appt.specialty = payload.specialty
        if payload.date is not None:
            appt.date = payload.date
        if payload.time is not None:
            appt.time = payload.time
        if payload.status is not None and payload.status.upper() in VALID_APPOINTMENT_STATUSES:
            appt.status = payload.status.upper()

        try:
            await db.commit()
        except IntegrityError:
            await db.rollback()
            return api_response_error(
                message=(
                    f"This time slot was just booked for {new_doctor} "
                    f"on {new_date}. Please pick another time."
                ),
                status_code=StatusCode.conflict,
            )
        await db.refresh(appt)

        return api_response_success(
            data=appointment_to_dict(appt),
            message=f"Appointment {appt.appointment_id} updated successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update appointment: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def delete_appointment_service(appointment_id: str, db: AsyncSession):
    try:
        appt = await find_appointment_by_id(db, appointment_id)
        if not appt:
            return api_response_error(
                message="Appointment not found",
                status_code=StatusCode.notFound,
            )

        await db.delete(appt)
        await db.commit()

        return api_response_success(
            data=None,
            message=f"Appointment {appointment_id} deleted successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to delete appointment: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Billing & Invoices ───────────────────────

async def list_invoices_service(db: AsyncSession):
    try:
        invoices = (
            (
                await db.execute(
                    select(Invoice).order_by(Invoice.created_at.desc())
                )
            )
            .scalars()
            .all()
        )
        return api_response_success(
            data=[invoice_to_dict(inv) for inv in invoices],
            message="Invoices fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch invoices: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def create_invoice_service(payload, db: AsyncSession):
    try:
        items = [item.model_dump() for item in payload.items] if payload.items else []
        amount = sum(item.get("cost", 0) for item in items)

        invoice = Invoice(
            invoice_id=await generate_invoice_id(db),
            patient_name=payload.patient_name,
            patient_phone=payload.patient_phone or None,
            date=payload.date,
            amount=amount,
            items=json.dumps(items),
            insurance_status=payload.insurance_status.upper()
            if payload.insurance_status in VALID_INSURANCE_STATUSES
            else "UNINSURED",
            payment_status=payload.payment_status.upper()
            if payload.payment_status in VALID_PAYMENT_STATUSES
            else "UNPAID",
        )
        db.add(invoice)
        await db.commit()
        await db.refresh(invoice)

        return api_response_success(
            data=invoice_to_dict(invoice),
            message=f"Invoice {invoice.invoice_id} created successfully",
            status_code=StatusCode.create,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to create invoice: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_invoice_service(invoice_id: str, payload, db: AsyncSession):
    try:
        invoice = await find_invoice_by_id(db, invoice_id)
        if not invoice:
            return api_response_error(
                message="Invoice not found",
                status_code=StatusCode.notFound,
            )

        if payload.patient_name is not None:
            invoice.patient_name = payload.patient_name
        if payload.patient_phone is not None:
            invoice.patient_phone = payload.patient_phone or None
        if payload.date is not None:
            invoice.date = payload.date
        if payload.items is not None:
            items = [item.model_dump() for item in payload.items]
            invoice.items = json.dumps(items)
            invoice.amount = sum(item.get("cost", 0) for item in items)
        if payload.insurance_status is not None:
            invoice.insurance_status = payload.insurance_status.upper()
        if payload.payment_status is not None and payload.payment_status.upper() in VALID_PAYMENT_STATUSES:
            invoice.payment_status = payload.payment_status.upper()

        await db.commit()
        await db.refresh(invoice)

        return api_response_success(
            data=invoice_to_dict(invoice),
            message=f"Invoice {invoice.invoice_id} updated successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update invoice: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def delete_invoice_service(invoice_id: str, db: AsyncSession):
    try:
        invoice = await find_invoice_by_id(db, invoice_id)
        if not invoice:
            return api_response_error(
                message="Invoice not found",
                status_code=StatusCode.notFound,
            )

        await db.delete(invoice)
        await db.commit()

        return api_response_success(
            data=None,
            message=f"Invoice {invoice_id} deleted successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to delete invoice: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Dashboard / Reports ───────────────────────

async def get_dashboard_service(db: AsyncSession):
    """Aggregate KPIs for the receptionist analytics tab."""
    try:
        today = _today()

        today_visits = (
            await db.execute(
                select(func.count()).select_from(OpdAppointment).where(
                    OpdAppointment.date == today
                )
            )
        ).scalar_one()

        checked_in_today = (
            await db.execute(
                select(func.count()).select_from(OpdAppointment).where(
                    OpdAppointment.date == today,
                    OpdAppointment.status == "CHECKED-IN",
                )
            )
        ).scalar_one()

        total_patients = (
            await db.execute(select(func.count()).select_from(Patient))
        ).scalar_one()

        paid_billings = (
            await db.execute(
                select(func.coalesce(func.sum(Invoice.amount), 0)).where(
                    Invoice.payment_status == "PAID"
                )
            )
        ).scalar_one()

        unpaid_billings = (
            await db.execute(
                select(func.coalesce(func.sum(Invoice.amount), 0)).where(
                    Invoice.payment_status == "UNPAID"
                )
            )
        ).scalar_one()

        unpaid_invoices = (
            await db.execute(
                select(func.count()).select_from(Invoice).where(
                    Invoice.payment_status == "UNPAID"
                )
            )
        ).scalar_one()

        total_beds = (
            await db.execute(select(func.count()).select_from(Bed))
        ).scalar_one()
        occupied_beds = (
            await db.execute(
                select(func.count()).select_from(Bed).where(
                    Bed.status == "OCCUPIED"
                )
            )
        ).scalar_one()

        pending_tasks = (
            await db.execute(
                select(func.count()).select_from(ClinicalTask).where(
                    ClinicalTask.status.in_(["PENDING", "IN-PROGRESS"])
                )
            )
        ).scalar_one()

        admitted = (
            await db.execute(
                select(func.count()).select_from(Admission).where(
                    Admission.status == "ADMITTED"
                )
            )
        ).scalar_one()

        occupancy = round((occupied_beds / total_beds) * 100) if total_beds else 0

        data = {
            "today_visits": today_visits,
            "checked_in_today": checked_in_today,
            "total_patients": total_patients,
            "paid_billings": paid_billings,
            "unpaid_billings": unpaid_billings,
            "unpaid_invoices": unpaid_invoices,
            "total_beds": total_beds,
            "occupied_beds": occupied_beds,
            "occupancy_rate": occupancy,
            "pending_tasks": pending_tasks,
            "admitted": admitted,
        }
        return api_response_success(
            data=data,
            message="Dashboard data fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch dashboard data: {str(e)}",
            status_code=StatusCode.internalServerError,
        )
