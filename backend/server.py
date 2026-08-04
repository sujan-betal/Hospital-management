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
from src.modules.hospital.hospital_routes import router as hospital_router
from src.modules.receptionist.receptionist_routes import router as receptionist_router
from src.modules.patient.patient_routes import router as patient_router


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
    from src.models.bed_model import Bed  # noqa: F401
    from src.models.admission_model import Admission  # noqa: F401
    from src.models.task_model import ClinicalTask  # noqa: F401
    from src.models.hospital_setting_model import HospitalSetting  # noqa: F401
    from src.models.opd_appointment_model import OpdAppointment  # noqa: F401
    from src.models.invoice_model import Invoice  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    statements = [
        "ALTER TABLE doctors ADD COLUMN IF NOT EXISTS phone VARCHAR",
        "ALTER TABLE doctors ADD COLUMN IF NOT EXISTS department VARCHAR",
        "ALTER TABLE doctors ADD COLUMN IF NOT EXISTS token TEXT",
        "ALTER TABLE doctors ADD COLUMN IF NOT EXISTS is_reset BOOLEAN DEFAULT FALSE",
        "ALTER TABLE doctors ADD COLUMN IF NOT EXISTS created_by UUID",
        "ALTER TABLE patients ADD COLUMN IF NOT EXISTS age INTEGER",
        "ALTER TABLE patients ADD COLUMN IF NOT EXISTS gender VARCHAR",
        "ALTER TABLE patients ADD COLUMN IF NOT EXISTS insurance_provider VARCHAR",
        "ALTER TABLE patients ADD COLUMN IF NOT EXISTS otp_code TEXT",
        "ALTER TABLE patients ADD COLUMN IF NOT EXISTS otp_expiry TIMESTAMPTZ",
    ]
    async with engine.begin() as conn:
        for statement in statements:
            await conn.execute(text(statement))


async def seed_hospital_data():
    """Insert demo beds/admissions/tasks/settings only when empty."""
    from sqlalchemy import func, select

    from src.config.database import SessionLocal
    from src.models.admission_model import Admission
    from src.models.bed_model import Bed
    from src.models.hospital_setting_model import HospitalSetting
    from src.models.task_model import ClinicalTask
    from src.modules.hospital.hospital_query import DEFAULT_SETTINGS
    from src.modules.hospital.seed_data import (
        SEED_ADMISSIONS,
        SEED_BEDS,
        SEED_TASKS,
    )

    async with SessionLocal() as db:
        if (
            await db.execute(
                select(func.count()).select_from(HospitalSetting)
            )
        ).scalar_one() == 0:
            db.add(HospitalSetting(**DEFAULT_SETTINGS))

        if (await db.execute(select(func.count()).select_from(Bed))).scalar_one() == 0:
            for row in SEED_BEDS:
                db.add(Bed(**row))

        if (
            await db.execute(select(func.count()).select_from(Admission))
        ).scalar_one() == 0:
            for row in SEED_ADMISSIONS:
                db.add(Admission(**row))

        if (
            await db.execute(select(func.count()).select_from(ClinicalTask))
        ).scalar_one() == 0:
            for row in SEED_TASKS:
                db.add(ClinicalTask(**row))

        await db.commit()


async def seed_receptionist_data():
    """Insert demo patients/appointments/invoices only when empty."""
    from sqlalchemy import func, select

    from src.config.database import SessionLocal
    from src.models.invoice_model import Invoice
    from src.models.opd_appointment_model import OpdAppointment
    from src.models.patient_model import Patient
    from src.modules.receptionist.seed_data import (
        SEED_APPOINTMENTS,
        SEED_INVOICES,
        SEED_PATIENTS,
    )

    async with SessionLocal() as db:
        if (
            await db.execute(select(func.count()).select_from(Patient))
        ).scalar_one() == 0:
            for row in SEED_PATIENTS:
                db.add(Patient(**row))

        if (
            await db.execute(select(func.count()).select_from(OpdAppointment))
        ).scalar_one() == 0:
            for row in SEED_APPOINTMENTS:
                db.add(OpdAppointment(**row))

        if (
            await db.execute(select(func.count()).select_from(Invoice))
        ).scalar_one() == 0:
            for row in SEED_INVOICES:
                db.add(Invoice(**row))

        await db.commit()


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("[STARTUP] Hospital Management backend running.")
    try:
        await ensure_schema()
        print("[STARTUP] Schema up to date (all tables present).")
        await seed_hospital_data()
        print("[STARTUP] Demo hospital data seeded (if tables were empty).")
        await seed_receptionist_data()
        print("[STARTUP] Demo receptionist data seeded (if tables were empty).")
    except Exception as exc:  # pragma: no cover - defensive startup
        print(f"[STARTUP] WARNING: could not ensure schema: {exc}")
    yield
    print("[SHUTDOWN] Server shutting down.")


app = FastAPI(title="Hospital Management Backend", version="1.0.0", lifespan=lifespan)
app.include_router(admin_router)
app.include_router(doctor_router)
app.include_router(hospital_router)
app.include_router(receptionist_router)
app.include_router(patient_router)


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
