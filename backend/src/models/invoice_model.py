from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.sql import func

from src.config.base import Base


class Invoice(Base):
    __tablename__ = "invoices"

    id = Column(Integer, primary_key=True, index=True)
    invoice_id = Column(String, unique=True, nullable=False)
    patient_name = Column(String, nullable=False)
    patient_phone = Column(String, nullable=True)
    date = Column(String, nullable=False)
    amount = Column(Integer, nullable=False, default=0)
    items = Column(Text, nullable=True)
    insurance_status = Column(String, nullable=False, default="UNINSURED")
    payment_status = Column(String, nullable=False, default="UNPAID")
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
