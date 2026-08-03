from sqlalchemy import Column, Integer, String, DateTime, Text
from sqlalchemy.sql import func

from src.config.base import Base


class Bed(Base):
    __tablename__ = "beds"

    id = Column(Integer, primary_key=True, index=True)
    bed_id = Column(String, unique=True, nullable=False)
    ward = Column(String, nullable=False, default="General Ward")
    status = Column(String, nullable=False, default="AVAILABLE")
    price = Column(Integer, nullable=False, default=0)
    floor = Column(Integer, nullable=False, default=1)
    assigned_nurse = Column(String, nullable=True)
    equipment = Column(Text, nullable=True)
    patient = Column(String, nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
