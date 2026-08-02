# backend/server.py

import os
import time
from contextlib import asynccontextmanager

from dotenv import load_dotenv
load_dotenv(".env")

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
import uvicorn

from src.modules.admin.admin_routes import router as admin_router
from src.modules.doctor.doctor_routes import router as doctor_router


async def ensure_schema():
    """Create any missing tables (doctors, patients, receptionists,
    permissions, ...) and backfill columns for the auth flow."""
    from src.config.base import Base
    from src.config.database import engine
    # Import all models so they register on Base.metadata.
    from src.models.admin_model import Admin  # noqa: F401
    from src.models.doctor_model import Doctor  # noqa: F401
    from src.models.patient_model import Patient  # noqa: F401
    from src.models.receptionist_model import Receptionist  # noqa: F401
    from src.models.permission_model import Permission  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    statements = [
        "ALTER TABLE doctors ADD COLUMN IF NOT EXISTS phone VARCHAR",
        "ALTER TABLE doctors ADD COLUMN IF NOT EXISTS department VARCHAR",
        "ALTER TABLE doctors ADD COLUMN IF NOT EXISTS token TEXT",
        "ALTER TABLE doctors ADD COLUMN IF NOT EXISTS is_reset BOOLEAN DEFAULT FALSE",
        "ALTER TABLE doctors ADD COLUMN IF NOT EXISTS created_by UUID",
    ]
    async with engine.begin() as conn:
        for statement in statements:
            await conn.execute(text(statement))


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("[STARTUP] Hospital Management backend running.")
    try:
        await ensure_schema()
        print("[STARTUP] Schema up to date (all tables present).")
    except Exception as exc:  # pragma: no cover - defensive startup
        print(f"[STARTUP] WARNING: could not ensure schema: {exc}")
    yield
    print("[SHUTDOWN] Server shutting down.")


app = FastAPI(title="Hospital Management Backend", version="1.0.0", lifespan=lifespan)
app.include_router(admin_router)
app.include_router(doctor_router)


allowed_origins = [
    origin.strip()
    for origin in os.getenv("FRONTEND_URI", "").split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def log_request_time(request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    print(f"{request.method} {request.url.path} - {(time.perf_counter() - start) * 1000:.2f} ms")
    return response






@app.get("/health")
async def health():
    return {"status": "ok"}


if __name__ == "__main__":     
    
    uvicorn.run(
        "server:app",
        host="localhost",
        port=int(os.getenv("PORT", 8005)),
        reload=os.getenv("NODE_ENV") != "production"
    )
