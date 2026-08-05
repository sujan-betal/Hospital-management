"""Alembic environment: async engine bound to the app's DATABASE_URL.

Migrations are plain idempotent SQL (ALTER ... IF NOT EXISTS, guarded
UPDATEs, CREATE INDEX IF NOT EXISTS) so they are safe to apply both on a
fresh database and on the existing Supabase database.
"""
import asyncio
import os
from logging.config import fileConfig

from dotenv import load_dotenv
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from alembic import context

load_dotenv()

from src.config.base import Base  # noqa: E402
# Import all models so they register on Base.metadata (used by create_all
# and future autogenerate).
from src.models.admin_model import Admin  # noqa: E402,F401
from src.models.doctor_model import Doctor  # noqa: E402,F401
from src.models.patient_model import Patient  # noqa: E402,F401
from src.models.receptionist_model import Receptionist  # noqa: E402,F401
from src.models.permission_model import Permission  # noqa: E402,F401
from src.models.bed_model import Bed  # noqa: E402,F401
from src.models.admission_model import Admission  # noqa: E402,F401
from src.models.task_model import ClinicalTask  # noqa: E402,F401
from src.models.hospital_setting_model import HospitalSetting  # noqa: E402,F401
from src.models.opd_appointment_model import OpdAppointment  # noqa: E402,F401
from src.models.invoice_model import Invoice  # noqa: E402,F401
from src.models.doctor_review_model import DoctorReview  # noqa: E402,F401

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

config.set_main_option("sqlalchemy.url", os.getenv("DATABASE_URL", ""))

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
        connect_args={"statement_cache_size": 0},
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
