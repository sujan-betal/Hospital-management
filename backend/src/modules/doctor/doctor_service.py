import os
from datetime import timedelta

from jose import jwt, JWTError
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.admin_model import Admin
from src.models.doctor_model import Doctor
from src.utils.common_schema import api_response_error, api_response_success
from src.utils.email import send_password_reset_email
from src.utils.security import (
    create_access_token,
    get_password_hash,
    verify_password,
)
from src.utils.status_code import StatusCode

RESET_TOKEN_EXPIRE_MINUTES = int(os.getenv("RESET_TOKEN_EXPIRE_MINUTES", "30"))
FRONTEND_URI = os.getenv("FRONTEND_URI", "http://localhost:3000")


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
    }


def _build_reset_link(token: str) -> str:
    return f"{FRONTEND_URI}/reset-password?token={token}"


def _create_reset_token(user_id, role: str) -> str:
    return create_access_token(
        subject=user_id,
        role=role,
        expires_delta=timedelta(minutes=RESET_TOKEN_EXPIRE_MINUTES),
    )


async def create_doctor_service(
    payload,
    created_by,
    db: AsyncSession,
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

        reset_token = _create_reset_token(doctor.user_id, "DOCTOR")
        doctor.token = reset_token

        db.add(doctor)
        await db.commit()
        await db.refresh(doctor)

        reset_link = _build_reset_link(reset_token)
        delivered = send_password_reset_email(
            to_email=doctor.email,
            full_name=doctor.user_name,
            reset_link=reset_link,
            reset_minutes=RESET_TOKEN_EXPIRE_MINUTES,
        )

        message = (
            "Doctor account created. A password-set email has been sent to "
            f"{doctor.email}."
            if delivered
            else "Doctor account created, but the password-set email could not be sent "
                 "to the doctor. Check the backend SMTP/console logs."
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


async def forgot_password_service(payload, db: AsyncSession):
    """Send a reset link to a doctor or admin by email."""
    try:
        email = payload.email

        query = select(Doctor).where(
            or_(Doctor.email == payload.email, Doctor.user_name == payload.email)
        )
        result = await db.execute(query)
        doctor = result.scalar_one_or_none()

        if doctor:
            reset_token = _create_reset_token(doctor.user_id, doctor.role)
            doctor.token = reset_token
            doctor.is_reset = True
            await db.commit()

            send_password_reset_email(
                to_email=doctor.email,
                full_name=doctor.user_name,
                reset_link=_build_reset_link(reset_token),
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
            reset_token = _create_reset_token(admin.user_id, admin.role)
            admin.token = reset_token
            admin.is_reset = True
            await db.commit()

            send_password_reset_email(
                to_email=admin.email,
                full_name=admin.user_name,
                reset_link=_build_reset_link(reset_token),
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
    """Set a new password using a valid reset token (doctors and admins)."""
    try:
        try:
            decoded = jwt.decode(
                payload.token,
                os.getenv("JWT_SECRET_KEY"),
                algorithms=[os.getenv("JWT_ALGORITHM", "HS256")],
            )
        except JWTError:
            return api_response_error(
                message="Invalid or expired reset link.",
                status_code=StatusCode.badRequest,
            )

        user_id = decoded.get("user_id")
        if not user_id:
            return api_response_error(
                message="Invalid reset link.",
                status_code=StatusCode.badRequest,
            )

        account = None
        role = (decoded.get("role") or "").upper()

        if role == "DOCTOR":
            result = await db.execute(
                select(Doctor).where(Doctor.user_id == user_id)
            )
            account = result.scalar_one_or_none()
        elif role in ("ADMIN", "SUBADMIN"):
            result = await db.execute(
                select(Admin).where(Admin.user_id == user_id)
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
