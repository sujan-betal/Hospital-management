from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.models.admin_model import Admin
from src.utils.security import verify_password, get_password_hash, create_access_token
from src.utils.common_schema import api_response_success, api_response_error
from src.utils.status_code import StatusCode
from src.modules.admin.admin_schema import AdminRegisterRequest, AdminLoginRequest
from src.modules.admin.admin_helper import format_admin_data

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
    try:
        # Find admin by email
        query = select(Admin).where(Admin.email == payload.email)
        result = await db.execute(query)
        admin = result.scalar_one_or_none()
        
        if not admin:
            return api_response_error(
                message="Invalid email or password",
                status_code=StatusCode.unauthorized
            )
            
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
            
        # Verify password
        if not verify_password(payload.password, admin.password):
            return api_response_error(
                message="Invalid email or password",
                status_code=StatusCode.unauthorized
            )
            
        # Create access token
        access_token = create_access_token(subject=admin.user_id, role=admin.role)
        
        # Save token in DB
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
        
    except Exception as e:
        return api_response_error(
            message=f"Login failed: {str(e)}",
            status_code=StatusCode.internalServerError
        )
