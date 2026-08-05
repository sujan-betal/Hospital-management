"""Backfill revenue split snapshots for payments made before the split feature.

Any appointment already marked PAID predates the dynamic-split snapshot, so
its admin_share / doctor_share columns are NULL. Backfill them from the
hospital-wide doctor share percentage that is configured today (falling back
to the 30% default if no settings row exists yet).

Revision ID: 0006
Revises: 0005
Create Date: 2026-08-05

"""
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0006"
down_revision: Union[str, None] = "0005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        UPDATE opd_appointments
        SET doctor_share_percent = COALESCE(
                (SELECT doctor_share_percent FROM hospital_settings LIMIT 1),
                30
            ),
            doctor_share = ROUND(fee * COALESCE(
                (SELECT doctor_share_percent FROM hospital_settings LIMIT 1),
                30
            ) / 100.0),
            admin_share = fee - ROUND(fee * COALESCE(
                (SELECT doctor_share_percent FROM hospital_settings LIMIT 1),
                30
            ) / 100.0)
        WHERE payment_status = 'PAID'
          AND (admin_share IS NULL OR doctor_share IS NULL)
        """
    )


def downgrade() -> None:
    op.execute(
        "UPDATE opd_appointments SET admin_share = NULL, doctor_share = NULL, "
        "doctor_share_percent = NULL WHERE payment_status = 'PAID'"
    )
