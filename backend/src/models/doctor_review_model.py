from sqlalchemy import Column, Integer, String, DateTime, Text
from sqlalchemy.sql import func

from src.config.base import Base


class DoctorReview(Base):
    """A patient's rating + comment for a doctor, left after their
    consultation is completed. One review per appointment."""

    __tablename__ = "doctor_reviews"

    id = Column(Integer, primary_key=True, index=True)
    review_id = Column(String, unique=True, nullable=False)
    appointment_id = Column(String, unique=True, nullable=False)
    doctor_id = Column(String, nullable=True)
    doctor_name = Column(String, nullable=False)
    specialty = Column(String, nullable=True)
    patient_user_id = Column(String, nullable=False)
    patient_name = Column(String, nullable=True)
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
