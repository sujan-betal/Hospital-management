"""RazorpayX (Payouts) integration for doctor settlement.

Doctor consultation payouts are routed through RazorpayX:
contact -> fund account (bank details) -> payout. Every helper is defensive:
if the RazorpayX keys are missing or the doctor has no bank details the
caller receives a clear "pending" reason instead of an exception, so a
payment is never blocked by payout configuration.

Set RAZORPAY_X_KEY_ID / RAZORPAY_X_KEY_SECRET in backend/.env to enable
automatic disbursement. Without them the split is still recorded and the
payout stays PENDING for the admin to settle manually.
"""

import os

from sqlalchemy.ext.asyncio import AsyncSession

from src.models.doctor_model import Doctor

PAYOUT_STATUS_PAID = "PAID"
PAYOUT_STATUS_PENDING = "PENDING"
PAYOUT_STATUS_FAILED = "FAILED"


def _razorpayx_client():
    key_id = os.getenv("RAZORPAY_X_KEY_ID", "").strip().strip("'")
    key_secret = os.getenv("RAZORPAY_X_KEY_SECRET", "").strip().strip("'")
    if not key_id or not key_secret:
        return None
    try:
        import razorpay
    except ImportError:
        return None
    return razorpay.Client(auth=(key_id, key_secret))


async def ensure_contact(db: AsyncSession, doctor: Doctor, client) -> str:
    """Return the RazorpayX contact id for a doctor, creating it if needed."""
    if doctor.razorpayx_contact_id:
        return doctor.razorpayx_contact_id

    contact = client.razorpayx.contact.create({
        "name": doctor.user_name,
        "email": doctor.email,
        "type": "vendor",
        "reference_id": str(doctor.user_id),
    })
    doctor.razorpayx_contact_id = contact.get("id")
    await db.commit()
    return doctor.razorpayx_contact_id


async def ensure_fund_account(
    db: AsyncSession, doctor: Doctor, client, contact_id: str
) -> str:
    """Return the RazorpayX fund account id for a doctor's bank account."""
    if doctor.razorpayx_fund_account_id:
        return doctor.razorpayx_fund_account_id

    fund = client.razorpayx.fund_account.create({
        "contact_id": contact_id,
        "account_type": "bank_account",
        "bank_account": {
            "name": doctor.bank_account_holder or doctor.user_name,
            "ifsc": doctor.bank_ifsc,
            "account_number": doctor.bank_account_number,
        },
    })
    doctor.razorpayx_fund_account_id = fund.get("id")
    await db.commit()
    return doctor.razorpayx_fund_account_id


async def attempt_doctor_payout(
    db: AsyncSession,
    doctor: Doctor | None,
    amount: int,
    reference_id: str,
) -> tuple[str, str | None, str | None]:
    """Try to disburse ``amount`` (in rupees) to ``doctor``.

    Returns (payout_status, payout_id, payout_error).
    Never raises: payment confirmation must not depend on payout success.
    """
    if amount <= 0:
        return PAYOUT_STATUS_PAID, None, None

    if doctor is None:
        return PAYOUT_STATUS_PENDING, None, "Doctor directory entry not found"

    if not (doctor.bank_ifsc and doctor.bank_account_number):
        return (
            PAYOUT_STATUS_PENDING,
            None,
            "Doctor bank details not provided",
        )

    client = _razorpayx_client()
    if client is None:
        return (
            PAYOUT_STATUS_PENDING,
            None,
            "RazorpayX payouts not configured",
        )

    try:
        contact_id = await ensure_contact(db, doctor, client)
        fund_account_id = await ensure_fund_account(db, doctor, client, contact_id)

        payout = client.razorpayx.payout.create({
            "fund_account_id": fund_account_id,
            "amount": amount * 100,
            "currency": "INR",
            "mode": "IMPS",
            "purpose": "vendor_payment",
            "queue_if_low_balance": True,
            "reference_id": reference_id[:30],
            "narration": "OPD consultation doctor payout",
        })
        return PAYOUT_STATUS_PAID, payout.get("id"), None
    except Exception as e:  # pragma: no cover - network/RazorpayX errors
        return PAYOUT_STATUS_FAILED, None, str(e)[:300]
