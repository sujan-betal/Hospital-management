"""Shared helpers for password-set / reset links.

Centralises the reset-token creation and link building that was previously
duplicated across the doctor, admin and receptionist modules. Also normalises
``FRONTEND_URI`` (which may contain several comma-separated origins for CORS)
down to a single origin so the emailed link is always a valid URL.
"""

import os
from datetime import timedelta

from src.utils.security import create_access_token

RESET_TOKEN_EXPIRE_MINUTES = int(os.getenv("RESET_TOKEN_EXPIRE_MINUTES", "30"))
# FRONTEND_URI may list multiple origins (for CORS); the reset link needs one.
RESET_LINK_URI = (
    os.getenv("RESET_LINK_URI")
    or os.getenv("FRONTEND_URI")
    or "http://localhost:3000"
).split(",")[0].strip().rstrip("/")


def build_reset_link(token: str) -> str:
    return f"{RESET_LINK_URI}/reset-password?token={token}"


def create_reset_token(user_id, role: str) -> str:
    return create_access_token(
        subject=user_id,
        role=role,
        expires_delta=timedelta(minutes=RESET_TOKEN_EXPIRE_MINUTES),
    )
