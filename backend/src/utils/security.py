import os
from datetime import datetime, timedelta, timezone
from typing import Union, Any
from jose import jwt
from passlib.context import CryptContext

from src.config.env import load_env

load_env()

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError

ph = PasswordHasher()

DEFAULT_JWT_SECRET = "aura-medical-dev-secret-change-me-in-production"
SECRET_KEY = os.getenv("JWT_SECRET_KEY") or DEFAULT_JWT_SECRET
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 1 day expiration by default

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        ph.verify(hashed_password, plain_password)
        return True
    except VerifyMismatchError:
        return False
    except Exception:
        # Fallback to bcrypt in case there are existing bcrypt-hashed passwords
        try:
            import bcrypt
            return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
        except Exception:
            return False

def get_password_hash(password: str) -> str:
    return ph.hash(password)

def create_access_token(subject: Union[str, Any], role: str, expires_delta: timedelta = None) -> str:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode = {
        "exp": expire,
        "user_id": str(subject),
        "role": role.upper()
    }
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
