from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete, or_
import os
from src.models.admin_model import Admin
from src.models.doctor_model import Doctor
from src.models.receptionist_model import Receptionist
from src.models.permission_model import Permission
from src.utils.security import verify_password, get_password_hash, create_access_token
from src.utils.email import send_password_reset_email
from src.utils.reset import (
    RESET_TOKEN_EXPIRE_MINUTES,
    build_reset_link,
    create_reset_token,
)
from src.utils.common_schema import api_response_success, api_response_error
from src.utils.status_code import StatusCode
from src.modules.admin.admin_schema import AdminRegisterRequest, AdminLoginRequest
from src.modules.admin.admin_helper import format_admin_data
from src.modules.admin.permissions_catalog import (
    PERMISSION_CATALOG,
    normalize_permissions,
)
from src.modules.doctor.doctor_service import format_doctor_bank_data

VALID_STATUSES = {"ACTIVE", "SUSPENDED", "INACTIVE"}

SHIFT_STATUS_MAP = {
    "ACTIVE": "On Duty",
    "SUSPENDED": "On Call",
    "INACTIVE": "Off Duty",
}


def _doctor_to_dict(doctor) -> dict:
    return {
        "user_id": str(doctor.user_id),
        "id": str(doctor.user_id),
        "name": doctor.user_name,
        "specialty": doctor.department or "General Medicine",
        "status": SHIFT_STATUS_MAP.get(doctor.status, "Off Duty"),
        "active_patients": 0,
        "email": doctor.email,
        "phone": doctor.phone,
        "department": doctor.department,
    }


async def _load_admin_permissions(db: AsyncSession, admin_id: int) -> list[str]:
    """Load the permission keys stored for an admin/subadmin account."""
    result = await db.execute(
        select(Permission.permission).where(Permission.admin_id == admin_id)
    )
    return sorted({(p or "").upper() for p in result.scalars().all() if p})


def _staff_to_dict(account, permissions: list[str] | None = None):
    data = {
        "user_id": str(account.user_id),
        "user_name": account.user_name,
        "email": account.email,
        "role": account.role,
        "status": account.status,
        "created_at": account.created_at,
    }
    if isinstance(account, Doctor):
        data["phone"] = account.phone
        data["department"] = account.department
    else:
        data["phone"] = None
        data["department"] = None

    # Admin / sub-admin accounts are permission-managed.
    if isinstance(account, Admin):
        data["admin_id"] = account.id
        data["permissions"] = permissions or []
    else:
        data["admin_id"] = None
        data["permissions"] = []

    return data


async def _get_staff_by_user_id(db: AsyncSession, user_id):
    result = await db.execute(select(Admin).where(Admin.user_id == user_id))
    account = result.scalar_one_or_none()
    if account:
        return account

    result = await db.execute(select(Doctor).where(Doctor.user_id == user_id))
    account = result.scalar_one_or_none()
    if account:
        return account

    result = await db.execute(
        select(Receptionist).where(Receptionist.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def _username_taken(db: AsyncSession, account, user_name: str) -> bool:
    model = type(account)
    result = await db.execute(
        select(model).where(model.user_name == user_name, model.id != account.id)
    )
    return result.scalar_one_or_none() is not None


async def _email_taken(db: AsyncSession, account, email: str) -> bool:
    model = type(account)
    result = await db.execute(
        select(model).where(model.email == email, model.id != account.id)
    )
    return result.scalar_one_or_none() is not None


async def list_staff_service(db: AsyncSession):
    try:
        admins = (await db.execute(
            select(Admin).where(Admin.is_deleted.is_(False))
        )).scalars().all()
        doctors = (await db.execute(select(Doctor))).scalars().all()
        receptionists = (await db.execute(select(Receptionist))).scalars().all()

        records = []
        for account in [*admins, *doctors, *receptionists]:
            permissions = None
            if isinstance(account, Admin):
                permissions = await _load_admin_permissions(db, account.id)
            records.append(_staff_to_dict(account, permissions))

        return api_response_success(
            data=records,
            message="Staff list fetched successfully",
            status_code=StatusCode.success,
        )

    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch staff: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def list_doctors_service(db: AsyncSession):
    try:
        doctors = (await db.execute(select(Doctor))).scalars().all()
        from src.modules.doctor.doctor_service import format_doctor_data

        records = [format_doctor_data(doctor) for doctor in doctors]

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


async def update_staff_service(user_id, payload, db: AsyncSession):
    try:
        account = await _get_staff_by_user_id(db, user_id)
        if not account:
            return api_response_error(
                message="Staff member not found",
                status_code=StatusCode.notFound,
            )

        if payload.user_name and payload.user_name != account.user_name:
            if await _username_taken(db, account, payload.user_name):
                return api_response_error(
                    message="Username already exists",
                    status_code=StatusCode.conflict,
                )
            account.user_name = payload.user_name

        if payload.email and payload.email.lower() != (account.email or "").lower():
            if await _email_taken(db, account, payload.email):
                return api_response_error(
                    message="Email already registered",
                    status_code=StatusCode.conflict,
                )
            account.email = payload.email

        if payload.status and payload.status.upper() in VALID_STATUSES:
            account.status = payload.status.upper()

        if isinstance(account, Doctor):
            if payload.phone is not None:
                account.phone = payload.phone
            if payload.department is not None:
                account.department = payload.department

        await db.commit()
        await db.refresh(account)

        return api_response_success(
            data=_staff_to_dict(account),
            message="Staff member updated successfully",
            status_code=StatusCode.success,
        )

    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update staff: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def delete_staff_service(user_id, current_admin, db: AsyncSession):
    try:
        account = await _get_staff_by_user_id(db, user_id)
        if not account:
            return api_response_error(
                message="Staff member not found",
                status_code=StatusCode.notFound,
            )

        if isinstance(account, Admin) and account.user_id == current_admin.user_id:
            return api_response_error(
                message="You cannot delete your own account",
                status_code=StatusCode.forbidden,
            )

        # Clean up permission rows for admin/subadmin accounts.
        if isinstance(account, Admin):
            await db.execute(delete(Permission).where(Permission.admin_id == account.id))

        await db.delete(account)
        await db.commit()

        return api_response_success(
            data=None,
            message=f"{account.role} account deleted permanently",
            status_code=StatusCode.success,
        )

    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to delete staff: {str(e)}",
            status_code=StatusCode.internalServerError,
        )

async def register_admin_service(
    payload: AdminRegisterRequest,
    db: AsyncSession
):
    try:
        # Check if email or username already exists
        query = select(Admin).where((Admin.email == payload.email) | (Admin.user_name == payload.user_name))
        result = await db.execute(query)
        existing_admin = result.scalar_one_or_none()
        
        if existing_admin:
            if existing_admin.email == payload.email:
                return api_response_error(
                    message="Email already registered",
                    status_code=StatusCode.conflict
                )
            else:
                return api_response_error(
                    message="Username already exists",
                    status_code=StatusCode.conflict
                )

        # Hash password and create admin
        hashed_password = get_password_hash(payload.password)
        new_admin = Admin(
            user_name=payload.user_name,
            email=payload.email,
            password=hashed_password,
            role="ADMIN",
            status="ACTIVE"
        )
        
        db.add(new_admin)
        await db.commit()
        await db.refresh(new_admin)
        
        admin_data = format_admin_data(new_admin)
        
        return api_response_success(
            data=admin_data,
            message="Admin registered successfully",
            status_code=StatusCode.create
        )
        
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Registration failed: {str(e)}",
            status_code=StatusCode.internalServerError
        )

async def login_admin_service(
    payload: AdminLoginRequest,
    db: AsyncSession
):
    return await login_staff_service(payload, db)

async def login_staff_service(
    payload: AdminLoginRequest,
    db: AsyncSession
):
    """Unified staff login: resolves the account across Admin, Doctor and
    Receptionist tables by email, then issues a role-scoped access token."""
    try:
        # 1) Admin / Sub-admin (match by email or username)
        identifier = payload.email
        query = select(Admin).where(
            or_(Admin.email == identifier, Admin.user_name == identifier)
        )
        result = await db.execute(query)
        admin = result.scalar_one_or_none()

        if admin:
            if admin.is_deleted:
                return api_response_error(
                    message="This account has been deleted",
                    status_code=StatusCode.forbidden
                )
            if admin.status != "ACTIVE":
                return api_response_error(
                    message=f"Account status is {admin.status}",
                    status_code=StatusCode.forbidden
                )
            if admin.is_reset:
                return api_response_error(
                    message="Please set your password using the link sent to your email.",
                    status_code=StatusCode.forbidden
                )
            if not verify_password(payload.password, admin.password):
                return api_response_error(
                    message="Invalid email or password",
                    status_code=StatusCode.unauthorized
                )

            access_token = create_access_token(subject=admin.user_id, role=admin.role)
            admin.token = access_token
            await db.commit()
            await db.refresh(admin)

            admin_data = format_admin_data(admin)
            admin_data["access_token"] = access_token
            admin_data["token_type"] = "bearer"

            return api_response_success(
                data=admin_data,
                message="Login successful",
                status_code=StatusCode.success
            )

        # 2) Doctor (match by email or username)
        doctor_query = select(Doctor).where(
            or_(Doctor.email == identifier, Doctor.user_name == identifier)
        )
        doctor_result = await db.execute(doctor_query)
        doctor = doctor_result.scalar_one_or_none()

        if doctor:
            if doctor.status != "ACTIVE":
                return api_response_error(
                    message=f"Account status is {doctor.status}",
                    status_code=StatusCode.forbidden
                )
            if doctor.is_reset:
                return api_response_error(
                    message="Please set your password using the link sent to your email.",
                    status_code=StatusCode.forbidden
                )
            if not verify_password(payload.password, doctor.password):
                return api_response_error(
                    message="Invalid email or password",
                    status_code=StatusCode.unauthorized
                )

            access_token = create_access_token(subject=doctor.user_id, role=doctor.role)
            doctor.token = access_token
            await db.commit()
            await db.refresh(doctor)

            doctor_data = {
                "id": doctor.id,
                "user_name": doctor.user_name,
                "email": doctor.email,
                "user_id": str(doctor.user_id),
                "role": doctor.role,
                "status": doctor.status,
                "phone": doctor.phone,
                "department": doctor.department,
            }
            doctor_data["access_token"] = access_token
            doctor_data["token_type"] = "bearer"

            return api_response_success(
                data=doctor_data,
                message="Login successful",
                status_code=StatusCode.success
            )

        # 3) Receptionist (match by email or username)
        rec_query = select(Receptionist).where(
            or_(Receptionist.email == identifier, Receptionist.user_name == identifier)
        )
        rec_result = await db.execute(rec_query)
        receptionist = rec_result.scalar_one_or_none()

        if receptionist:
            if receptionist.status != "ACTIVE":
                return api_response_error(
                    message=f"Account status is {receptionist.status}",
                    status_code=StatusCode.forbidden
                )
            if receptionist.is_reset:
                return api_response_error(
                    message="Please set your password using the link sent to your email.",
                    status_code=StatusCode.forbidden
                )
            if not verify_password(payload.password, receptionist.password):
                return api_response_error(
                    message="Invalid email or password",
                    status_code=StatusCode.unauthorized
                )

            access_token = create_access_token(
                subject=receptionist.user_id, role=receptionist.role
            )

            rec_data = {
                "id": receptionist.id,
                "user_name": receptionist.user_name,
                "email": receptionist.email,
                "user_id": str(receptionist.user_id),
                "role": receptionist.role,
                "status": receptionist.status,
            }
            rec_data["access_token"] = access_token
            rec_data["token_type"] = "bearer"

            return api_response_success(
                data=rec_data,
                message="Login successful",
                status_code=StatusCode.success
            )

        return api_response_error(
            message="Invalid email or password",
            status_code=StatusCode.unauthorized
        )

    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Login failed: {str(e)}",
            status_code=StatusCode.internalServerError
        )


async def create_subadmin_service(
    payload,
    created_by,
    db: AsyncSession
):
    """Create a SUBADMIN account and grant the requested permissions."""
    try:
        query = select(Admin).where(
            (Admin.email == payload.email) | (Admin.user_name == payload.user_name)
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
                status_code=StatusCode.conflict
            )

        new_subadmin = Admin(
            user_name=payload.user_name,
            email=payload.email,
            password=get_password_hash(os.urandom(24).hex()),
            role="SUBADMIN",
            status="ACTIVE",
            is_reset=True,
            created_by=created_by,
        )
        db.add(new_subadmin)
        await db.flush()  # assign id

        permissions = normalize_permissions(payload.permissions)
        for perm in permissions:
            db.add(Permission(admin_id=new_subadmin.id, permission=perm))

        await db.commit()
        await db.refresh(new_subadmin)

        # user_id is only assigned after commit, so build the reset token now
        # to avoid embedding "None" as the UUID in the emailed link.
        reset_token = create_reset_token(new_subadmin.user_id, "SUBADMIN")
        new_subadmin.token = reset_token
        await db.commit()
        await db.refresh(new_subadmin)

        reset_link = build_reset_link(reset_token)
        delivered, email_reason = send_password_reset_email(
            to_email=new_subadmin.email,
            full_name=new_subadmin.user_name,
            reset_link=reset_link,
            reset_minutes=RESET_TOKEN_EXPIRE_MINUTES,
            login_email=new_subadmin.email,
            login_username=new_subadmin.user_name,
        )

        admin_data = format_admin_data(new_subadmin)
        admin_data["permissions"] = permissions

        message = (
            "Sub-admin created successfully with assigned permissions. A password-set "
            f"email has been sent to {new_subadmin.email}."
            if delivered
            else f"Sub-admin created successfully with assigned permissions, but the "
                 f"password-set email could not be sent to {new_subadmin.email}. "
                 f"{email_reason}"
        )

        return api_response_success(
            data=admin_data,
            message=message,
            status_code=StatusCode.create
        )

    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to create sub-admin: {str(e)}",
            status_code=StatusCode.internalServerError
        )


async def assign_permissions_service(
    payload,
    db: AsyncSession
):
    """Replace the permission set of a permission-managed user (admin/subadmin/doctor/receptionist)."""
    try:
        query = select(Admin).where(Admin.id == payload.admin_id)
        result = await db.execute(query)
        user = result.scalar_one_or_none()

        if not user:
            return api_response_error(
                message="User not found",
                status_code=StatusCode.notFound
            )

        await db.execute(delete(Permission).where(Permission.admin_id == payload.admin_id))
        permissions = normalize_permissions(payload.permissions)
        for perm in permissions:
            db.add(Permission(admin_id=payload.admin_id, permission=perm))

        await db.commit()

        return api_response_success(
            data={"admin_id": payload.admin_id, "permissions": permissions},
            message="Permissions updated successfully",
            status_code=StatusCode.success
        )

    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update permissions: {str(e)}",
            status_code=StatusCode.internalServerError
        )


async def list_permissions_service(db: AsyncSession):
    """Return the catalog of assignable permissions, grouped for the UI."""
    try:
        return api_response_success(
            data=PERMISSION_CATALOG,
            message="Permission catalog fetched successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        return api_response_error(
            message=f"Failed to fetch permission catalog: {str(e)}",
            status_code=StatusCode.internalServerError,
        )


async def update_doctor_bank_details_service(user_id: str, payload, db: AsyncSession):
    """Admin: update a doctor's payout bank details by user_id."""
    try:
        result = await db.execute(select(Doctor).where(Doctor.user_id == user_id))
        doctor = result.scalar_one_or_none()

        if not doctor:
            return api_response_error(
                message="Doctor not found",
                status_code=StatusCode.notFound,
            )

        doctor.bank_account_holder = payload.account_holder
        doctor.bank_account_number = payload.account_number
        doctor.bank_ifsc = payload.ifsc
        doctor.bank_name = payload.bank_name
        doctor.upi_id = payload.upi_id
        await db.commit()
        await db.refresh(doctor)

        return api_response_success(
            data=format_doctor_bank_data(doctor),
            message="Doctor bank details updated successfully",
            status_code=StatusCode.success,
        )
    except Exception as e:
        await db.rollback()
        return api_response_error(
            message=f"Failed to update doctor bank details: {str(e)}",
            status_code=StatusCode.internalServerError,
        )
