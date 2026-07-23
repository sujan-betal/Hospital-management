import asyncio
import traceback
from sqlalchemy import text
from src.config.database import SupabaseSessionLocal

async def test_supabase():
    try:
        async with SupabaseSessionLocal() as db:
            result = await db.execute(text("SELECT version()"))
            print(result.scalar())
    except Exception:
        traceback.print_exc()

asyncio.run(test_supabase())