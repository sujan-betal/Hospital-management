from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func

from src.config.base import Base


class OpdAppointment(Base):
    __tablename__ = "opd_appointments"

    id = Column(Integer, primary_key=True, index=True)
    appointment_id = Column(String, unique=True, nullable=False)
    patient_name = Column(String, nullable=False)
    patient_phone = Column(String, nullable=True)
    patient_user_id = Column(String, nullable=True)
    doctor_name = Column(String, nullable=False)
    specialty = Column(String, nullable=False, default="General Medicine")
    date = Column(String, nullable=False)
    time = Column(String, nullable=False)
    status = Column(String, nullable=False, default="SCHEDULED")
    fee = Column(Integer, nullable=False, default=150)
    payment_status = Column(String, nullable=False, default="UNPAID")
    razorpay_order_id = Column(String, nullable=True)
    payment_id = Column(String, nullable=True)
    payment_signature = Column(String, nullable=True)
    doctor_share_percent = Column(Integer, nullable=True)
    admin_share = Column(Integer, nullable=True)
    doctor_share = Column(Integer, nullable=True)
    payout_status = Column(String, nullable=True, default="NOT_CONFIGURED")
    payout_id = Column(String, nullable=True)
    payout_error = Column(String, nullable=True)
    payout_date = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
