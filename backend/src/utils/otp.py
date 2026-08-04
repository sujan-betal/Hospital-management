"""OTP generation and delivery helpers for the Patient module.

OTPs are delivered over SMS via Twilio. When Twilio credentials are missing
(dev environments), the OTP is printed to the server console and returned to
the caller by the service layer so the login flow can be exercised end-to-end.
"""

import logging
import os
import random
from datetime import datetime, timedelta, timezone

from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

OTP_LENGTH = 6
OTP_TTL_MINUTES = 5

TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID", "")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN", "")
TWILIO_PHONE_NUMBER = os.getenv("TWILIO_PHONE_NUMBER", "")


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
    """Return True when all Twilio credentials are present in .env."""
    return bool(TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN and TWILIO_PHONE_NUMBER)


def send_otp_to_phone(phone: str, otp: str) -> bool:
    """Deliver the OTP to a phone number via Twilio SMS.

    Returns True when the SMS was dispatched. Falls back to printing the code
    to the server console when Twilio is not configured or delivery fails, so
    the demo flow keeps working without an SMS vendor.
    """
    if sms_configured():
        try:
            from twilio.rest import Client

            client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
            message = client.messages.create(
                body=f"Your AURA Medical login OTP is {otp}. It is valid for {OTP_TTL_MINUTES} minutes.",
                from_=TWILIO_PHONE_NUMBER,
                to=phone,
            )
            logger.info("OTP SMS sent via Twilio to %s (sid=%s)", phone, message.sid)
            print(f"[SMS SENT -> {phone}] via Twilio (sid={message.sid})")
            return True
        except Exception as exc:
            logger.error("Failed to send OTP SMS to %s: %s", phone, exc)
            print(f"[SMS FAILED -> {phone}] {exc}")

    print(f"\n[DEV OTP -> {phone}] Your AURA Medical OTP is {otp} (valid {OTP_TTL_MINUTES} min)\n")
    return False
