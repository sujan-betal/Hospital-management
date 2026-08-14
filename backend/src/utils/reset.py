"""Shared helpers for password-set / reset links.

Centralises the reset-token creation and link building that was previously
duplicated across the doctor, admin and receptionist modules. Also normalises
``FRONTEND_URI`` (which may contain several comma-separated origins for CORS)
down to a single origin so the emailed link is always a valid URL.

``build_reset_link`` prefers the configured ``RESET_LINK_URI`` so the emailed
link is always stable and reachable by the recipient. For local development
this must match the port the Flutter web app is served on — run it via
``flutter/run_web.ps1`` (pinned to 57087) so the URL in every email points at a
running app. The browser ``Origin`` is only used as a last-resort fallback when
``RESET_LINK_URI`` cannot be read from ``backend/.env``.
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
    # Emailed links must not depend on the admin's browser session (which can
    # be a random `flutter run` port that dies on restart), so RESET_LINK_URI
    # wins. `origin` is only a fallback when no RESET_LINK_URI is configured.
    base = RESET_LINK_URI or origin or "http://localhost:3000"
    # The Flutter web app uses the default hash router, so the reset link must
    # carry the route + token in the fragment: http://localhost:57087/#/reset-password?token=...
    return f"{base.rstrip('/')}/#/reset-password?token={token}"


def create_reset_token(user_id, role: str) -> str:
    return create_access_token(
        subject=user_id,
        role=role,
        expires_delta=timedelta(minutes=RESET_TOKEN_EXPIRE_MINUTES),
    )
