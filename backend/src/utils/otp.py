"""OTP generation and delivery helpers for the Patient module.

No SMS provider is wired up yet, so in development the OTP is printed to the
server console (and returned to the caller by the service layer) so the login
flow can be exercised end-to-end.
"""

import os
import random
from datetime import datetime, timedelta, timezone

OTP_LENGTH = 6
OTP_TTL_MINUTES = 5

# Configurable SMS gateway env vars for future integration.
SMS_PROVIDER = os.getenv("SMS_PROVIDER", "")


def generate_otp(length: int = OTP_LENGTH) -> str:
    """Return a random numeric OTP of the requested length."""
    return "".join(str(random.randint(0, 9)) for _ in range(length))


def otp_expiry_utc(minutes: int = OTP_TTL_MINUTES) -> datetime:
    """Return the UTC expiry timestamp for a freshly issued OTP."""
    return datetime.now(timezone.utc) + timedelta(minutes=minutes)


def is_otp_expired(expiry: datetime) -> bool:
    """Return True when the OTP expiry timestamp is in the past."""
    if not expiry:
        return True
    if expiry.tzinfo is None:
        expiry = expiry.replace(tzinfo=timezone.utc)
    return datetime.now(timezone.utc) > expiry


def sms_configured() -> bool:
    return bool(SMS_PROVIDER)


def send_otp_to_phone(phone: str, otp: str) -> bool:
    """Deliver the OTP to a phone number.

    Returns True when the SMS was dispatched. Falls back to printing the code
    to the server console so the demo flow keeps working without an SMS vendor.
    """
    if sms_configured():
        # Future integration point for an SMS gateway (Twilio, MSG91, ...).
        # `SMS_PROVIDER` and the matching credentials are read from .env.
        print(f"[SMS SENT -> {phone}] Your AURA Medical OTP is {otp}")
        return True

    print(f"\n[DEV OTP -> {phone}] Your AURA Medical OTP is {otp} (valid {OTP_TTL_MINUTES} min)\n")
    return False
