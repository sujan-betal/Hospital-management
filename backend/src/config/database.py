import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
    async_sessionmaker,
)

from .base import Base

load_dotenv()

# ==========================
# Local PostgreSQL
# ==========================

LOCAL_DATABASE_URL = (
    f"postgresql+asyncpg://"
    f"{os.getenv('LOCAL_DB_USER')}:"
    f"{os.getenv('LOCAL_DB_PASSWORD')}@"
    f"{os.getenv('LOCAL_DB_HOST')}:"
    f"{os.getenv('LOCAL_DB_PORT')}/"
    f"{os.getenv('LOCAL_DB_NAME')}"
)

local_engine = create_async_engine(
    LOCAL_DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    pool_recycle=300,
    pool_size=10,
    max_overflow=20,
)

LocalSessionLocal = async_sessionmaker(
    bind=local_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# ==========================
# Supabase PostgreSQL
# ==========================

SUPABASE_DATABASE_URL = (
    f"postgresql+asyncpg://"
    f"{os.getenv('SUPABASE_DB_USER')}:"
    f"{os.getenv('SUPABASE_DB_PASSWORD')}@"
    f"{os.getenv('SUPABASE_DB_HOST')}:"
    f"{os.getenv('SUPABASE_DB_PORT')}/"
    f"{os.getenv('SUPABASE_DB_NAME')}"
)

supabase_engine = create_async_engine(
    SUPABASE_DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    pool_recycle=300,
    pool_size=10,
    max_overflow=20,
)

SupabaseSessionLocal = async_sessionmaker(
    bind=supabase_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# ==========================
# Local Dependency
# ==========================

async def get_local_db():
    async with LocalSessionLocal() as db:
        try:
            yield db
        finally:
            await db.close()

# ==========================
# Supabase Dependency
# ==========================

async def get_supabase_db():
    async with SupabaseSessionLocal() as db:
        try:
            yield db
        finally:
            await db.close()



print("Host:", os.getenv("SUPABASE_DB_HOST"))
print("Port:", os.getenv("SUPABASE_DB_PORT"))
print("User:", os.getenv("SUPABASE_DB_USER"))
print("DB:", os.getenv("SUPABASE_DB_NAME"))
print(SUPABASE_DATABASE_URL)