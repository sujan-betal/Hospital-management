from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from jose import jwt, JWTError
import logging
import os
from dotenv import load_dotenv

load_dotenv()

from src.config.database import get_db

from src.models.admin_model import Admin
from src.models.doctor_model import Doctor
from src.models.receptionist_model import Receptionist
from src.models.patient_model import Patient
from src.models.permission_model import Permission


logger = logging.getLogger(__name__)

# Fallback so auth works even if JWT_SECRET_KEY is not set on the host
# (e.g. fresh deployment). Override it in production with a strong secret.
DEFAULT_JWT_SECRET = "aura-medical-dev-secret-change-me-in-production"
SECRET_KEY = os.getenv("JWT_SECRET_KEY") or DEFAULT_JWT_SECRET
ALGORITHM = os.getenv("JWT_ALGORITHM") or "HS256"

if not os.getenv("JWT_SECRET_KEY"):
    logger.warning(
        "JWT_SECRET_KEY not set on this environment. Using the built-in "
        "fallback secret - set JWT_SECRET_KEY on the host for production."
    )

security = HTTPBearer()

ROLE_MODEL_MAP = {
    "ADMIN": Admin,
    "SUBADMIN": Admin,
    "DOCTOR": Doctor,
    "RECEPTIONIST": Receptionist,
    "PATIENT": Patient,
}

# ---------------------------------------------------------
# Local + Supabase are mirrored (same schema, same data, same
# inserts happen on both). So reads only need ONE DB — no need
# to query both. Switch this single value to "supabase" if you
# ever want all reads to come from Supabase instead.
# ---------------------------------------------------------
READ_DB = "local"  # "local" or "supabase"

# Roles that go through the Permission table check (admin_id FK on Permission)
PERMISSION_ROLES = ("ADMIN", "SUBADMIN", "DOCTOR", "RECEPTIONIST")

# Roles that skip permission checks entirely (authenticated + role-allowed is enough)
NO_PERMISSION_ROLES = ("PATIENT",)


def authorization(allowed_roles: list = None, required_permissions: list = None):
    allowed_roles = allowed_roles or []
    required_permissions = required_permissions or []

    async def authorize_user(
        credentials: HTTPAuthorizationCredentials = Depends(security),
        db: AsyncSession = Depends(get_db),
    ):
        try:
            token = credentials.credentials

            try:
                decoded = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            except JWTError:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired token",
                )

            user_id = decoded.get("user_id")
            role = (decoded.get("role") or "").upper()

            if not role:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token: role missing",
                )

            model = ROLE_MODEL_MAP.get(role)
            if not model:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid role",
                )

            result = await db.execute(
                select(model).where(model.user_id == user_id)
            )
            existing_user = result.scalar_one_or_none()

            if not existing_user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found"
                )

            # --- Role allowlist check ---
            if allowed_roles:
                allowed = [r.upper() for r in allowed_roles]
                if role not in allowed:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Access denied: invalid role",
                    )

            # --- Roles with no permission-table check ---
            if role in NO_PERMISSION_ROLES:
                return existing_user

            # --- Permission-based roles ---
            permissions_data = []
            if role in PERMISSION_ROLES:
                perm_result = await db.execute(
                    select(Permission).where(Permission.admin_id == existing_user.id)
                )
                permissions_data = perm_result.scalars().all()

            permissions = [(p.permission or "").upper() for p in permissions_data]

            if "ALL" in permissions:
                return existing_user

            if required_permissions:
                if not all(
                    permission.upper() in permissions
                    for permission in required_permissions
                ):
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Access denied: insufficient permissions",
                    )

            return existing_user

        except HTTPException:
            raise

        except Exception as error:
            logger.error("AUTH ERROR: %s", error, exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Internal server error",
            )

    return authorize_user