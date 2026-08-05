"""De-duplicate OPD slots and enforce a unique active slot per doctor.

Cleans up appointments that share a doctor/date/time (a legacy double-click
bug) keeping the earliest row, then adds a partial unique index so one
doctor/date/time slot can only ever be held by a single active appointment.

Revision ID: 0004
Revises: 0003
Create Date: 2026-08-05

"""
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0004"
down_revision: Union[str, None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        DELETE FROM opd_appointments a
        USING opd_appointments b
        WHERE a.id > b.id
          AND a.doctor_name = b.doctor_name
          AND a.date = b.date
          AND a.time = b.time
          AND a.status != 'CANCELLED'
          AND b.status != 'CANCELLED'
        """
    )
    op.execute(
        """
        CREATE UNIQUE INDEX IF NOT EXISTS ux_opd_slot_active
        ON opd_appointments (doctor_name, date, time)
        WHERE status != 'CANCELLED'
        """
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ux_opd_slot_active")
