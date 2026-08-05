"""Dynamic revenue split between hospital and doctors.

Adds a configurable doctor share percentage on hospital settings plus a
per-payment split snapshot (admin share / doctor share) on paid OPD
appointments.

Revision ID: 0005
Revises: 0004
Create Date: 2026-08-05

"""
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0005"
down_revision: Union[str, None] = "0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TABLE hospital_settings ADD COLUMN IF NOT EXISTS doctor_share_percent INTEGER DEFAULT 30")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS doctor_share_percent INTEGER")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS admin_share INTEGER")
    op.execute("ALTER TABLE opd_appointments ADD COLUMN IF NOT EXISTS doctor_share INTEGER")


def downgrade() -> None:
    op.execute("ALTER TABLE hospital_settings DROP COLUMN IF EXISTS doctor_share_percent")
    for column in ["doctor_share_percent", "admin_share", "doctor_share"]:
        op.execute(f"ALTER TABLE opd_appointments DROP COLUMN IF EXISTS {column}")
