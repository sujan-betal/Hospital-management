import os
import uuid

from jose import jwt, JWTError
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.admin_model import Admin
from src.models.doctor_model import Doctor
from src.models.receptionist_model import Receptionist
from src.utils.common_schema import api_response_error, api_response_success
from src.utils.email import send_password_reset_email
from src.utils.reset import (
    RESET_TOKEN_EXPIRE_MINUTES,
    build_reset_link,
    create_reset_token,
)
from src.utils.security import (
    create_access_token,
    get_password_hash,
    verify_password,
)
from src.utils.status_code import StatusCode


def format_doctor_data(doctor: Doctor) -> dict:
    return {
        "id": doctor.id,
        "user_name": doctor.user_name,
        "email": doctor.email,
        "user_id": str(doctor.user_id),
        "role": doctor.role,
        "status": doctor.status,
        "phone": doctor.phone,
        "department": doctor.department,
        "rating": round(float(doctor.rating), 1) if doctor.rating is not None else 4.0,
        "review_count": doctor.review_count or 0,
        "experience_years": doctor.experience_years or 0,
        "is_top_rated": (doctor.rating or 4.0) >= 4.5,
        "has_bank_details": bool(doctor.bank_ifsc and doctor.bank_account_number),
        "bank_account_holder": doctor.bank_account_holder or "",
        "bank_account_number": _mask_account_number(doctor.bank_account_number),
        "bank_ifsc": doctor.bank_ifsc or "",
        "bank_name": doctor.bank_name or "",
        "upi_id": doctor.upi_id or "",
        "razorpayx_fund_account_id": doctor.razorpayx_fund_account_id or "",
    }


async def create_doctor_service(
    payload,
    created_by,
    db: AsyncSession,
    origin: str | None = None,
):
    """Admin-only: create a doctor account and email a password-set link."""
    try:
        query = select(Doctor).where(
            (Doctor.email == payload.email) | (Doctor.user_name == payload.user_name)
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

        # No usable password yet: the doctor must set one via the emailed link.
        doctor = Doctor(
            user_name=payload.user_name,
            email=payload.email,
            phone=payload.phone,
            department=payload.department,
            password=get_password_hash(os.urandom(24).hex()),
            role="DOCTOR",
            status="ACTIVE",
            is_reset=True,
            created_by=created_by,
        )

        db.add(doctor)
        await db.commit()
        await db.refresh(doctor)

        # user_id is only assigned after commit, so build the reset token now
        # to avoid embedding "None" as the UUID in the emailed link.
        reset_token = create_reset_token(doctor.user_id, "DOCTOR")
        doctor.token = reset_token
        await db.commit()
        await db.refresh(doctor)

        reset_link = build_reset_link(reset_token, origin)
        delivered, email_reason = send_password_reset_email(
            to_email=doctor.email,
            full_name=doctor.user_name,
            reset_link=reset_link,
            reset_minutes=RESET_TOKEN_EXPIRE_MINUTES,
            login_email=doctor.email,
            login_username=doctor.user_name,
        )

        message = (
            "Doctor account created. A password-set email has been sent to "
            f"{doctor.email}."
            if delivered
            else f"Doctor account created, but the password-set email could not be "
                 f"sent to {doctor.email}. {email_reason}"
        )

        return api_response_success(
            data=format_doctor_data(doctor),
            message=message,
            status_code=StatusCode.create,
        )

    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to create doctor: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def login_doctor_service(payload, db: AsyncSession):
    try:
        query = select(Doctor).where(
            or_(Doctor.email == payload.email, Doctor.user_name == payload.email)
        )
        result = await db.execute(query)
        doctor = result.scalar_one_or_none()

        if not doctor:
            return api_response_error(
                message="Invalid email/username or password",
                status_code=StatusCode.unauthorized,
            )

        if doctor.status != "ACTIVE":
            return api_response_error(
                message=f"Account status is {doctor.status}",
                status_code=StatusCode.forbidden,
            )

        # Doctor must set their password through the emailed reset link first.
        if doctor.is_reset:
            return api_response_error(
                message="Please set your password using the link sent to your email.",
                status_code=StatusCode.forbidden,
            )

        if not verify_password(payload.password, doctor.password):
            return api_response_error(
                message="Invalid email or password",
                status_code=StatusCode.unauthorized,
            )

        access_token = create_access_token(
            subject=doctor.user_id, role=doctor.role
        )
        doctor.token = access_token
        await db.commit()
        await db.refresh(doctor)

        doctor_data = format_doctor_data(doctor)
        doctor_data["access_token"] = access_token
        doctor_data["token_type"] = "bearer"

        return api_response_success(
            data=doctor_data,
            message="Login successful",
            status_code=StatusCode.success,
        )

    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Login failed: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def forgot_password_service(payload, db: AsyncSession, origin: str | None = None):
    """Send a reset link to a doctor or admin by email."""
    try:
        email = payload.email

        query = select(Doctor).where(
            or_(Doctor.email == payload.email, Doctor.user_name == payload.email)
        )
        result = await db.execute(query)
        doctor = result.scalar_one_or_none()

        if doctor:
            reset_token = create_reset_token(doctor.user_id, doctor.role)
            doctor.token = reset_token
            doctor.is_reset = True
            await db.commit()

            send_password_reset_email(
                to_email=doctor.email,
                full_name=doctor.user_name,
                reset_link=build_reset_link(reset_token, origin),
                reset_minutes=RESET_TOKEN_EXPIRE_MINUTES,
            )

            return api_response_success(
                data=None,
                message="If an account exists for that email, a reset link has been sent.",
                status_code=StatusCode.success,
            )

        admin_query = select(Admin).where(
            or_(Admin.email == email, Admin.user_name == email)
        )
        admin_result = await db.execute(admin_query)
        admin = admin_result.scalar_one_or_none()

        if admin:
            reset_token = create_reset_token(admin.user_id, admin.role)
            admin.token = reset_token
            admin.is_reset = True
            await db.commit()

            send_password_reset_email(
                to_email=admin.email,
                full_name=admin.user_name,
                reset_link=build_reset_link(reset_token, origin),
                reset_minutes=RESET_TOKEN_EXPIRE_MINUTES,
            )

        receptionist_query = select(Receptionist).where(
            or_(Receptionist.email == email, Receptionist.user_name == email)
        )
        receptionist_result = await db.execute(receptionist_query)
        receptionist = receptionist_result.scalar_one_or_none()

        if receptionist:
            reset_token = create_reset_token(receptionist.user_id, receptionist.role)
            receptionist.token = reset_token
            receptionist.is_reset = True
            await db.commit()

            send_password_reset_email(
                to_email=receptionist.email,
                full_name=receptionist.user_name,
                reset_link=build_reset_link(reset_token, origin),
                reset_minutes=RESET_TOKEN_EXPIRE_MINUTES,
            )

        # Always return the same generic response to avoid leaking accounts.
        return api_response_success(
            data=None,
            message="If an account exists for that email, a reset link has been sent.",
            status_code=StatusCode.success,
        )

    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to send reset link: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def reset_password_service(payload, db: AsyncSession):
    """Set a new password using a valid reset token (doctors, admins, receptionists)."""
    try:
        try:
            decoded = jwt.decode(
                payload.token,
                os.getenv("JWT_SECRET_KEY") or "aura-medical-dev-secret-change-me-in-production",
                algorithms=[os.getenv("JWT_ALGORITHM", "HS256")],
            )
        except JWTError:
            return api_response_error(
                message="Invalid or expired reset link.",
                status_code=StatusCode.badRequest,
            )

        user_id = decoded.get("user_id")
        try:
            user_uuid = uuid.UUID(str(user_id))
        except (TypeError, ValueError):
            return api_response_error(
                message="Invalid or expired reset link.",
                status_code=StatusCode.badRequest,
            )

        account = None
        role = (decoded.get("role") or "").upper()

        if role == "DOCTOR":
            result = await db.execute(
                select(Doctor).where(Doctor.user_id == user_uuid)
            )
            account = result.scalar_one_or_none()
        elif role == "RECEPTIONIST":
            result = await db.execute(
                select(Receptionist).where(Receptionist.user_id == user_uuid)
            )
            account = result.scalar_one_or_none()
        elif role in ("ADMIN", "SUBADMIN"):
            result = await db.execute(
                select(Admin).where(Admin.user_id == user_uuid)
            )
            account = result.scalar_one_or_none()

        if not account:
            return api_response_error(
                message="Invalid reset link.",
                status_code=StatusCode.badRequest,
            )

        # The stored token must match to prevent reusing old links.
        if not account.token or account.token != payload.token:
            return api_response_error(
                message="Invalid or expired reset link.",
                status_code=StatusCode.badRequest,
            )

        account.password = get_password_hash(payload.new_password)
        account.token = None
        account.is_reset = False
        await db.commit()

        return api_response_success(
            data=None,
            message="Password updated successfully. You can now sign in.",
            status_code=StatusCode.success,
        )

    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to reset password: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


# ─────────────────────── Bank details & payouts ───────────────────────

def _mask_account_number(account_number: str | None) -> str:
    if not account_number:
        return ""
    if len(account_number) <= 4:
        return account_number
    return "XXXX" + account_number[-4:]


def format_doctor_bank_data(doctor: Doctor) -> dict:
    return {
        "account_holder": doctor.bank_account_holder or "",
        "account_number": doctor.bank_account_number or "",
        "ifsc": doctor.bank_ifsc or "",
        "bank_name": doctor.bank_name or "",
        "upi_id": doctor.upi_id or "",
        "has_bank_details": bool(doctor.bank_ifsc and doctor.bank_account_number),
        "razorpayx_contact_id": doctor.razorpayx_contact_id or "",
        "razorpayx_fund_account_id": doctor.razorpayx_fund_account_id or "",
    }


async def get_bank_details_service(current_doctor, db: AsyncSession):
    try:
        return api_response_success(
            data=format_doctor_bank_data(current_doctor),
            message="Bank details fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch bank details: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_bank_details_service(current_doctor, payload, db: AsyncSession):
    try:
        current_doctor.bank_account_holder = payload.account_holder
        current_doctor.bank_account_number = payload.account_number
        current_doctor.bank_ifsc = payload.ifsc
        current_doctor.bank_name = payload.bank_name
        current_doctor.upi_id = payload.upi_id
        await db.commit()
        await db.refresh(current_doctor)

        return api_response_success(
            data=format_doctor_bank_data(current_doctor),
            message="Bank details saved. Payouts will be sent to this account.",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to save bank details: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def get_doctor_earnings_service(current_doctor, db: AsyncSession):
    """Summarise the doctor's own consultation earnings and payout status."""
    try:
        from src.models.opd_appointment_model import OpdAppointment
        from src.modules.patient.patient_query import appointment_to_dict

        result = await db.execute(
            select(OpdAppointment)
            .where(
                OpdAppointment.payment_status == "PAID",
                OpdAppointment.doctor_name == current_doctor.user_name,
            )
            .order_by(OpdAppointment.updated_at.desc())
        )
        paid = result.scalars().all()

        total_earned = 0
        paid_out = 0
        pending = 0
        for appt in paid:
            doctor_share = appt.doctor_share if appt.doctor_share is not None else 0
            total_earned += doctor_share
            if appt.payout_status == "PAID":
                paid_out += doctor_share
            else:
                pending += doctor_share

        return api_response_success(
            data={
                "bank": format_doctor_bank_data(current_doctor),
                "summary": {
                    "total_earned": total_earned,
                    "paid_out": paid_out,
                    "pending": pending,
                    "payments_count": len(paid),
                    "doctor_share_percent": paid[0].doctor_share_percent
                    if paid and paid[0].doctor_share_percent is not None
                    else 0,
                },
                "payments": [appointment_to_dict(a) for a in paid],
            },
            message="Earnings fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch earnings: {str(e)}",
            status_code=StatusCode.internalServerError,
        )
