from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func

from src.config.base import Base


class ClinicalTask(Base):
    __tablename__ = "clinical_tasks"

    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(String, unique=True, nullable=False)
    bed_id = Column(String, nullable=False, default="—")
    task_description = Column(String, nullable=False)
    priority = Column(String, nullable=False, default="MEDIUM")
    assigned_to = Column(String, nullable=False, default="Nursing Staff")
    status = Column(String, nullable=False, default="PENDING")
    task_type = Column(String, nullable=False, default="NURSING")
    timestamp = Column(String, nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
