"""Chore ORM model."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, CheckConstraint, DateTime, String, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base

DIFFICULTIES = ("easy", "medium", "hard", "flexible")
CADENCES = ("daily", "weekly", "monthly", "on_request")


class Chore(Base):
    """A chore template available to submit."""

    __tablename__ = "chores"
    __table_args__ = (
        CheckConstraint(
            "difficulty IN ('easy','medium','hard','flexible')",
            name="chores_difficulty_check",
        ),
        CheckConstraint(
            "cadence IN ('daily','weekly','monthly','on_request')",
            name="chores_cadence_check",
        ),
    )

    chore_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default=func.gen_random_uuid(),
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    difficulty: Mapped[str] = mapped_column(String(20), nullable=False)
    cadence: Mapped[str] = mapped_column(String(20), nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
