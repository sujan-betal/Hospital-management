from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func

from src.config.base import Base


class HospitalSetting(Base):
    __tablename__ = "hospital_settings"

    id = Column(Integer, primary_key=True, index=True)
    hospital_name = Column(String, nullable=False, default="AURA Medical Center & ICU")
    address = Column(String, nullable=True)
    currency = Column(String, nullable=False, default="INR (Rs.)")
    copay_rate = Column(Integer, nullable=False, default=10)
    emergency_markup = Column(Integer, nullable=False, default=25)
    doctor_share_percent = Column(Integer, nullable=False, default=30)
    auto_telemetry = Column(Boolean, nullable=False, default=True)
    sanitation_interval = Column(Integer, nullable=False, default=12)
    auto_dirty = Column(Boolean, nullable=False, default=True)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
