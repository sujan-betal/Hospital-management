import asyncio
from sqlalchemy import text

from src.config.database import AsyncSessionLocal


async def main():
    async with AsyncSessionLocal() as db:
        result = await db.execute(text("SELECT version()"))
        print(result.scalar())


asyncio.run(main())