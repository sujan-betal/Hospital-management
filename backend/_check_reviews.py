import asyncio
from sqlalchemy import text
from src.config.database import engine


async def go():
    async with engine.connect() as c:
        r = await c.execute(text(
            "SELECT column_name FROM information_schema.columns "
            "WHERE table_name='doctor_reviews' ORDER BY ordinal_position"
        ))
        for row in r:
            print(row[0])


asyncio.run(go())
