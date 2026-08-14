# backend/server.py

import os
import re
import time
from contextlib import asynccontextmanager

from src.config.env import load_env
load_env()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from src.modules.admin.admin_routes import router as admin_router
from src.modules.doctor.doctor_routes import router as doctor_router
from src.modules.hospital.hospital_routes import router as hospital_router
from src.modules.receptionist.receptionist_routes import router as receptionist_router
from src.modules.patient.patient_routes import router as patient_router


async def run_migrations():
    """Apply Alembic migrations (schema/column changes) before serving.

    Schema changes live in alembic/versions/ instead of app code, so this is
    a thin wrapper around `alembic upgrade head`. Runs in a subprocess to
    avoid event-loop conflicts with the async app.
    """
    import subprocess
    import sys

    backend_dir = os.path.dirname(os.path.abspath(__file__))
    result = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=backend_dir,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"alembic upgrade head failed:\n{result.stdout}\n{result.stderr}"
        )


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


async def seed_default_admin():
    """Ensure the default super-admin login (`admin` / `Admin@1234`) exists.

    If an `admin` username already exists (e.g. registered manually), its
    password is reset to the documented default so the login always works.
    """
    from sqlalchemy import select

    from src.config.database import SessionLocal
    from src.models.admin_model import Admin
    from src.utils.security import get_password_hash

    default_email = "admin@aurahospital.com"

    async with SessionLocal() as db:
        result = await db.execute(
            select(Admin).where(Admin.user_name == "admin")
        )
        admin = result.scalar_one_or_none()

        if admin:
            db.add(admin)
            admin.password = get_password_hash("Admin@1234")
            admin.role = "ADMIN"
            admin.status = "ACTIVE"
            admin.is_reset = False
            admin.is_deleted = False
            await db.commit()
            return

        db.add(
            Admin(
                user_name="admin",
                email=default_email,
                password=get_password_hash("Admin@1234"),
                role="ADMIN",
                status="ACTIVE",
            )
        )
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


async def seed_demo_doctors():
    """Insert demo doctors (with ratings) only when the hospital has fewer
    than 5 active doctors, so real admin-created directories stay intact."""
    import os

    from sqlalchemy import func, select

    from src.config.database import SessionLocal
    from src.models.doctor_model import Doctor
    from src.modules.doctor.seed_data import DEMO_DOCTORS
    from src.utils.security import get_password_hash

    async with SessionLocal() as db:
        active = (
            await db.execute(
                select(func.count()).select_from(Doctor).where(
                    Doctor.status == "ACTIVE"
                )
            )
        ).scalar_one()

        if active < 5:
            existing_emails = {
                row[0]
                for row in (await db.execute(select(Doctor.email))).all()
            }
            for demo in DEMO_DOCTORS:
                if demo["email"] not in existing_emails:
                    row = dict(demo)
                    # Demo doctors can't log in until an admin resets their
                    # password; they exist as directory entries for booking.
                    row["password"] = get_password_hash(os.urandom(24).hex())
                    row["is_reset"] = True
                    db.add(Doctor(**row))
            await db.commit()


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("[STARTUP] Hospital Management backend running.")
    try:
        await run_migrations()
        print("[STARTUP] Schema migrations applied (alembic upgrade head).")
        await seed_default_admin()
        print("[STARTUP] Default admin seeded (`admin` / `Admin@1234`).")
        await seed_demo_doctors()
        print("[STARTUP] Demo doctor directory ensured.")
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

# Flutter's `flutter run -d chrome` / `web-server` picks a random localhost
# port on every launch, so a local web app can never be listed explicitly in
# FRONTEND_URI. Allow any localhost / 127.0.0.1 origin so the dev Flutter app
# can talk to this backend whether it runs locally or is deployed (e.g.
# Render). The explicit FRONTEND_URI list still governs real deployed
# frontends, and the JWT flow only uses headers (no cookies).
LOCALHOST_ORIGIN_RE = re.compile(r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$")

# Development builds serve the browser app from an arbitrary localhost port
# (Flutter `flutter run -d chrome` picks a random port; Next.js uses 3000).
# Without a matching CORS rule the browser blocks the login fetch preflight,
# so nothing ever appears in the DevTools Network tab. The JWT flow only uses
# headers (no cookies), so we can relax CORS in dev and keep the strict
# FRONTEND_URI allow-list for production.
is_dev = os.getenv("APP_ENV", "development").lower() == "development"

cors_options = {
    "allow_origins": ["*"] if is_dev else allowed_origins,
    "allow_origin_regex": LOCALHOST_ORIGIN_RE,
    "allow_credentials": not is_dev,
    "allow_methods": ["*"],
    "allow_headers": ["*"],
}
app.add_middleware(CORSMiddleware, **cors_options)


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
