import os

from sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
    async_sessionmaker,
)

from .base import Base
from .env import load_env

load_env()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    pool_recycle=300,
    connect_args={
        "statement_cache_size": 0
    }
)

SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

async def get_db():
    async with SessionLocal() as db:
        try:
            yield db
        finally:
            await db.close()