"""Difficulty -> reward mapping ORM model."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, Float, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class DifficultyReward(Base):
    """Maps (household, difficulty tier, reward category) -> numeric value."""

    __tablename__ = "difficulty_rewards"
    __table_args__ = (
        CheckConstraint(
            "difficulty IN ('easy','medium','hard','flexible')",
            name="difficulty_rewards_difficulty_check",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default=func.gen_random_uuid(),
    )
    household_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("households.household_id", ondelete="CASCADE"),
        nullable=False,
    )
    difficulty: Mapped[str] = mapped_column(String(20), nullable=False)
    reward_category_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("reward_categories.reward_category_id", ondelete="CASCADE"),
        nullable=False,
    )
    value: Mapped[float] = mapped_column(Float, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
