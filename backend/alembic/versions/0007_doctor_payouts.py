"""Doctor bank details + per-payment payout tracking.

Adds the bank account / RazorpayX identifiers doctors need for automatic
payouts, plus payout status fields on paid OPD appointments so every payment
records whether the doctor's share was disbursed.

Revision ID: 0007
Revises: 0006
Create Date: 2026-08-05

"""
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0007"
down_revision: Union[str, None] = "0006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS bank_account_holder VARCHAR")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS bank_ifsc VARCHAR")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS bank_name VARCHAR")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS upi_id VARCHAR")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS razorpayx_contact_id VARCHAR")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS razorpayx_fund_account_id VARCHAR")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS payout_status VARCHAR")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS payout_id VARCHAR")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS payout_error VARCHAR")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS payout_date TIMESTAMP WITH TIME ZONE")


def downgrade() -> None:
    for column in [
        "bank_account_holder", "bank_account_number", "bank_ifsc",
        "bank_name", "upi_id", "razorpayx_contact_id", "razorpayx_fund_account_id",
    ]:
        op.execute(f"ALTER TABLE doctors DROP COLUMN IF EXISTS {column}")
    for column in ["payout_status", "payout_id", "payout_error", "payout_date"]:
        op.execute(f"ALTER TABLE opd_appointments DROP COLUMN IF EXISTS {column}")
