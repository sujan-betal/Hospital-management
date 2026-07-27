import os
import sys
from logging.config import fileConfig

from sqlalchemy.ext.asyncio import create_async_engine
from alembic import context
from dotenv import load_dotenv

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

load_dotenv()

REQUIRED_VARS = [
    "LOCAL_DB_USER", "LOCAL_DB_PASSWORD", "LOCAL_DB_HOST", "LOCAL_DB_PORT", "LOCAL_DB_NAME",
    "SUPABASE_DB_USER", "SUPABASE_DB_PASSWORD", "SUPABASE_DB_HOST", "SUPABASE_DB_PORT", "SUPABASE_DB_NAME",
]
missing = [v for v in REQUIRED_VARS if not os.getenv(v)]
if missing:
    raise RuntimeError(
        f"Missing env vars: {missing}. "
        f"Check that .env exists and is being loaded from the right directory "
        f"(cwd when running alembic: {os.getcwd()})"
    )

from src.config.base import Base

# Import every model so Base.metadata knows about all tables.
# If you don't have a src/models/__init__.py that imports them all,
# import each model explicitly below instead:
from src.models.admin_model import Admin          # noqa: F401
# from src.models.doctor_model import Doctor        # noqa: F401
# from src.models.receptionist_model import Receptionist  # noqa: F401
# from src.models.patient_model import Patient      # noqa: F401
# from src.models.permission_model import Permission  # noqa: F401

config = context.config

# Both local and Supabase must stay in sync — migrations run on BOTH.
LOCAL_DATABASE_URL = (
    f"postgresql+asyncpg://"
    f"{os.getenv('LOCAL_DB_USER')}:"
    f"{os.getenv('LOCAL_DB_PASSWORD')}@"
    f"{os.getenv('LOCAL_DB_HOST')}:"
    f"{os.getenv('LOCAL_DB_PORT')}/"
    f"{os.getenv('LOCAL_DB_NAME')}"
)

SUPABASE_DATABASE_URL = (
    f"postgresql+asyncpg://"
    f"{os.getenv('SUPABASE_DB_USER')}:"
    f"{os.getenv('SUPABASE_DB_PASSWORD')}@"
    f"{os.getenv('SUPABASE_DB_HOST')}:"
    f"{os.getenv('SUPABASE_DB_PORT')}/"
    f"{os.getenv('SUPABASE_DB_NAME')}"
    f"?ssl=require"
)

TARGET_DATABASE_URLS = [LOCAL_DATABASE_URL, SUPABASE_DATABASE_URL]

print(f"[alembic] LOCAL_DB_HOST={os.getenv('LOCAL_DB_HOST')} LOCAL_DB_PORT={os.getenv('LOCAL_DB_PORT')}")
print(f"[alembic] SUPABASE_DB_HOST={os.getenv('SUPABASE_DB_HOST')} SUPABASE_DB_PORT={os.getenv('SUPABASE_DB_PORT')}")

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    for url in TARGET_DATABASE_URLS:
        context.configure(
            url=url,
            target_metadata=target_metadata,
            literal_binds=True,
            dialect_opts={"paramstyle": "named"},
        )
        with context.begin_transaction():
            context.run_migrations()


def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online() -> None:
    for url in TARGET_DATABASE_URLS:
        connectable = create_async_engine(url)
        async with connectable.connect() as connection:
            await connection.run_sync(do_run_migrations)
        await connectable.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    import asyncio
    asyncio.run(run_migrations_online())