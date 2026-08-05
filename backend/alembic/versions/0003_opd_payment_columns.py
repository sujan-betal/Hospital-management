"""OPD appointment and invoice billing columns.

Adds the fee / payment fields used by the patient booking and online-payment
flow, plus the patient_phone lookup on invoices.

Revision ID: 0003
Revises: 0002
Create Date: 2026-08-05

"""
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TABLE invoices ADD COLUMN IF NOT EXISTS patient_phone VARCHAR")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS patient_user_id VARCHAR")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS fee INTEGER DEFAULT 150")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS payment_status VARCHAR DEFAULT 'UNPAID'")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS razorpay_order_id VARCHAR")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS payment_id VARCHAR")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS payment_signature VARCHAR")


def downgrade() -> None:
    for column in [
        "patient_user_id", "fee", "payment_status",
        "razorpay_order_id", "payment_id", "payment_signature",
    ]:
        op.execute(f"ALTER TABLE opd_appointments DROP COLUMN IF EXISTS {column}")
    op.execute("ALTER TABLE invoices DROP COLUMN IF EXISTS patient_phone")
