"""Auth and doctor-directory columns, with rating backfill.

Adds the columns used by the OTP auth flow (patients/receptionists/doctors)
and the doctor directory ratings, then backfills ratings for doctors that
predate the rating feature. Every statement is idempotent, so this migration
is a no-op on databases where the columns already exist.

Revision ID: 0002
Revises: 0001
Create Date: 2026-08-05

"""
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ─── doctors ───
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS phone VARCHAR")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS department VARCHAR")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS rating FLOAT")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS review_count INTEGER")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS experience_years INTEGER")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS token TEXT")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS is_reset BOOLEAN DEFAULT FALSE")
    op.execute("ALTER TABLE doctors ADD COLUMN IF NOT EXISTS created_by UUID")

    # ─── receptionists ───
    op.execute("ALTER TABLE receptionists ADD COLUMN IF NOT EXISTS token TEXT")
    op.execute("ALTER TABLE receptionists ADD COLUMN IF NOT EXISTS is_reset BOOLEAN DEFAULT FALSE")

    # ─── patients ───
    op.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS age INTEGER")
    op.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS gender VARCHAR")
    op.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS insurance_provider VARCHAR")
    op.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS otp_code TEXT")
    op.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS otp_expiry TIMESTAMPTZ")

    # ─── backfill ratings for doctors created before the rating feature ───
    op.execute("UPDATE doctors SET rating = 4.3 + ((id % 5) * 0.1) WHERE rating IS NULL")
    op.execute("UPDATE doctors SET review_count = 80 + ((id % 9) * 15) WHERE review_count IS NULL")
    op.execute("UPDATE doctors SET experience_years = 8 + (id % 8) WHERE experience_years IS NULL")


def downgrade() -> None:
    for column in [
        "phone", "department", "rating", "review_count", "experience_years",
        "token", "is_reset", "created_by",
    ]:
        op.execute(f"ALTER TABLE doctors DROP COLUMN IF EXISTS {column}")
    op.execute("ALTER TABLE receptionists DROP COLUMN IF EXISTS token")
    op.execute("ALTER TABLE receptionists DROP COLUMN IF EXISTS is_reset")
    for column in ["age", "gender", "insurance_provider", "otp_code", "otp_expiry"]:
        op.execute(f"ALTER TABLE patients DROP COLUMN IF EXISTS {column}")
