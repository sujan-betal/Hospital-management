"""Shared helpers for password-set / reset links.

Centralises the reset-token creation and link building that was previously
duplicated across the doctor, admin and receptionist modules. Also normalises
``FRONTEND_URI`` (which may contain several comma-separated origins for CORS)
down to a single origin so the emailed link is always a valid URL.

``build_reset_link`` prefers the browser ``Origin`` of the request that
triggered the email. Flutter's `flutter run -d chrome` picks a random port on
every run, so the reset link built from a hardcoded origin would point at an
app that isn't running. Using the live origin keeps the emailed link correct no
matter which port the dev server chose.
"""

import os
from datetime import timedelta
from urllib.parse import urlsplit

from fastapi import Request

from src.utils.security import create_access_token

RESET_TOKEN_EXPIRE_MINUTES = int(os.getenv("RESET_TOKEN_EXPIRE_MINUTES", "30"))
# FRONTEND_URI may list multiple origins (for CORS); the reset link needs one.
RESET_LINK_URI = (
    os.getenv("RESET_LINK_URI")
    or os.getenv("FRONTEND_URI")
    or "http://localhost:3000"
).split(",")[0].strip().rstrip("/")


def _clean_origin(raw: str) -> str | None:
    """Return a scheme://host[:port] origin, or None if the value is unusable."""
    if not raw:
        return None
    try:
        parts = urlsplit(raw.strip())
    except ValueError:
        return None
    if parts.scheme not in ("http", "https") or not parts.netloc:
        return None
    return f"{parts.scheme}://{parts.netloc}"


def request_origin(request: Request) -> str | None:
    """Best-effort origin of the browser that made this request.

    Uses the ``Origin`` header first (sent on every fetch), falling back to
    ``Referer``. Returns None when neither is usable so callers can fall back
    to ``RESET_LINK_URI``.
    """
    origin = request.headers.get("origin")
    if origin:
        cleaned = _clean_origin(origin)
        if cleaned:
            return cleaned
    referer = request.headers.get("referer")
    if referer:
        return _clean_origin(referer)
    return None


def build_reset_link(token: str, origin: str | None = None) -> str:
    base = origin or RESET_LINK_URI
    # The Flutter web app uses the default hash router, so the reset link must
    # carry the route + token in the fragment: http://localhost:57087/#/reset-password?token=...
    return f"{base.rstrip('/')}/#/reset-password?token={token}"


def create_reset_token(user_id, role: str) -> str:
    return create_access_token(
        subject=user_id,
        role=role,
        expires_delta=timedelta(minutes=RESET_TOKEN_EXPIRE_MINUTES),
    )
