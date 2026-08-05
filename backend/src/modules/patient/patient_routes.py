import uuid as uuid_lib

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.database import get_db
from src.middleware.auth import authorization
from src.modules.patient.patient_schema import (
    PatientAppointmentCreateRequest,
    PatientAppointmentUpdateRequest,
    PatientCreateRequest,
    PatientOtpSendRequest,
    PatientOtpVerifyRequest,
    PatientPaymentVerifyRequest,
    PatientReviewCreateRequest,
    PatientUpdateRequest,
)
from src.modules.patient.patient_service import (
    book_appointment_service,
    create_patient_service,
    create_payment_order_service,
    delete_patient_service,
    get_patient_profile_service,
    get_patient_service,
    list_booked_slots_service,
    list_patient_appointments_service,
    list_patient_doctors_service,
    list_patient_invoices_service,
    list_patient_reviews_service,
    list_patients_service,
    send_otp_service,
    submit_doctor_review_service,
    update_patient_appointment_service,
    update_patient_profile_service,
    update_patient_service,
    verify_otp_service,
    verify_payment_service,
)

router = APIRouter(prefix="/api/patient", tags=["Patient"])

PATIENT_ROLES = ["PATIENT"]
STAFF_ROLES = ["ADMIN", "SUBADMIN", "RECEPTIONIST"]


@router.post("")
async def create_patient(
    payload: PatientCreateRequest,
    staff=Depends(authorization(allowed_roles=STAFF_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await create_patient_service(payload, db)


@router.post("/otp/send")
async def send_patient_otp(
    payload: PatientOtpSendRequest,
    db: AsyncSession = Depends(get_db),
):
    return await send_otp_service(payload, db)


@router.post("/otp/verify")
async def verify_patient_otp(
    payload: PatientOtpVerifyRequest,
    db: AsyncSession = Depends(get_db),
):
    return await verify_otp_service(payload, db)


@router.get("/me")
async def get_profile(
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await get_patient_profile_service(patient, db)


@router.put("/me")
async def update_profile(
    payload: PatientUpdateRequest,
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await update_patient_profile_service(patient, payload, db)


@router.get("/doctors")
async def list_doctors(
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await list_patient_doctors_service(db)


@router.get("/appointments")
async def list_appointments(
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await list_patient_appointments_service(patient, db)


@router.get("/appointments/booked-slots")
async def booked_slots(
    date: str,
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await list_booked_slots_service(date, db)


@router.post("/appointments")
async def book_appointment(
    payload: PatientAppointmentCreateRequest,
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await book_appointment_service(patient, payload, db)


@router.put("/appointments/{appointment_id}")
async def update_appointment(
    appointment_id: str,
    payload: PatientAppointmentUpdateRequest,
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await update_patient_appointment_service(patient, appointment_id, payload, db)


@router.post("/appointments/{appointment_id}/payment/order")
async def create_payment_order(
    appointment_id: str,
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await create_payment_order_service(patient, appointment_id, db)


@router.post("/appointments/{appointment_id}/payment/verify")
async def verify_payment(
    appointment_id: str,
    payload: PatientPaymentVerifyRequest,
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await verify_payment_service(patient, appointment_id, payload, db)


@router.get("/invoices")
async def list_invoices(
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await list_patient_invoices_service(patient, db)


@router.get("/reviews")
async def list_reviews(
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await list_patient_reviews_service(patient, db)


@router.post("/reviews")
async def submit_review(
    payload: PatientReviewCreateRequest,
    patient=Depends(authorization(allowed_roles=PATIENT_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await submit_doctor_review_service(patient, payload, db)


@router.get("")
async def list_patients(
    staff=Depends(authorization(allowed_roles=STAFF_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await list_patients_service(db)


@router.get("/{user_id}")
async def get_patient(
    user_id: uuid_lib.UUID,
    staff=Depends(authorization(allowed_roles=STAFF_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await get_patient_service(user_id, db)


@router.put("/{user_id}")
async def update_patient(
    user_id: uuid_lib.UUID,
    payload: PatientUpdateRequest,
    staff=Depends(authorization(allowed_roles=STAFF_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await update_patient_service(user_id, payload, db)


@router.delete("/{user_id}")
async def delete_patient(
    user_id: uuid_lib.UUID,
    staff=Depends(authorization(allowed_roles=STAFF_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    return await delete_patient_service(user_id, db)
