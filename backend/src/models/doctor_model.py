from sqlalchemy import Column, Integer, String, DateTime, Text, Boolean
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import UUID
import uuid

from src.config.base import Base

class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(Integer, primary_key=True, index=True)
    user_name = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False) 
    password = Column(Text, nullable=True)
    user_id = Column(
        UUID(as_uuid=True),
        default=uuid.uuid4,
        unique=True,
        nullable=False
    )
    status = Column(
        String,
        default="ACTIVE"
    )
    role = Column(
        String,
        default="DOCTOR"
    )
    phone = Column(
        String,
        nullable=True
    )
    department = Column(
        String,
        nullable=True
    )
    token = Column(
        Text, nullable=True)
    is_reset = Column(
        Boolean,
        default=False,
        server_default="false",
        nullable=False
    )
    created_by = Column(
        UUID(as_uuid=True),
        nullable=True
    )
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
