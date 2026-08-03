from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func

from src.config.base import Base


class Admission(Base):
    __tablename__ = "admissions"

    id = Column(Integer, primary_key=True, index=True)
    admission_id = Column(String, unique=True, nullable=False)
    patient_name = Column(String, nullable=False)
    patient_age = Column(Integer, nullable=False, default=0)
    patient_gender = Column(String, nullable=False, default="Male")
    ward_type = Column(String, nullable=False, default="General Ward")
    bed_id = Column(String, nullable=True, default="Pending")
    admit_date = Column(String, nullable=False)
    discharge_date = Column(String, nullable=True)
    billing_amount = Column(Integer, nullable=False, default=0)
    status = Column(String, nullable=False, default="ADMITTED")
    insurance_status = Column(String, nullable=False, default="COVERED")
    patient_email = Column(String, nullable=True)
    patient_phone = Column(String, nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
