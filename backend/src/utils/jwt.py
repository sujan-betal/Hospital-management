from jose import jwt, JWTError, ExpiredSignatureError
from dotenv import load_dotenv
from datetime import datetime, timedelta
from typing import Optional
import os

from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session


load_dotenv()

DEFAULT_JWT_SECRET = "aura-medical-dev-secret-change-me-in-production"
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")

# Fail fast in production: never fall back to the known default secret.
if os.getenv("APP_ENV", "development") == "production":
    SECRET_KEY = os.getenv("JWT_SECRET_KEY")
    if not SECRET_KEY or SECRET_KEY == DEFAULT_JWT_SECRET:
        raise RuntimeError(
            "JWT_SECRET_KEY must be set to a strong, unique value in production"
        )
else:
    SECRET_KEY = os.getenv("JWT_SECRET_KEY") or DEFAULT_JWT_SECRET

ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_DAYS   = 30

# auto_error=False so we handle missing token with a clear message ourselves
security = HTTPBearer(auto_error=False)

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire    = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire    = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
