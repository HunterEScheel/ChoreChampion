"""Chore submission ORM model."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Text, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class ChoreSubmission(Base):
    """A single attempt to complete a chore.

    ``approved`` defaults to TRUE (auto-approve on submit, decision 4b).
    Admins can later flip it to FALSE via the reject endpoint, storing a reason
    in ``rejection_reason``.

    Note: ``local_date`` (DB column) is ``GENERATED ALWAYS AS ((completed_at AT
    TIME ZONE 'UTC')::date) STORED`` and is intentionally not mapped here — it
    exists purely to back the ``uniq_submission_per_member_per_day`` unique
    index as a DB-level safety net. The authoritative tz-aware check runs in
    ``services/submission_rules.py``.
    """

    __tablename__ = "chore_submissions"

    submission_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default=func.gen_random_uuid(),
    )
    chore_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("chores.chore_id", ondelete="CASCADE"),
        nullable=False,
    )
    member_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("family_members.member_id", ondelete="CASCADE"),
        nullable=False,
    )
    device_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("devices.device_id", ondelete="CASCADE"),
        nullable=False,
    )
    household_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("households.household_id", ondelete="CASCADE"),
        nullable=False,
    )
    completed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    approved: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    rejection_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
