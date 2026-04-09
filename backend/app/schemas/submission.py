"""Chore submission request/response schemas."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class SubmissionCreateRequest(BaseModel):
    """Body for POST /submissions. `member_id` comes from the X-Active-Member header."""

    chore_id: uuid.UUID
    notes: str | None = Field(default=None, max_length=2000)


class SubmissionRead(BaseModel):
    """Public view of a submission."""

    model_config = ConfigDict(from_attributes=True)

    submission_id: uuid.UUID
    chore_id: uuid.UUID
    member_id: uuid.UUID
    device_id: uuid.UUID
    household_id: uuid.UUID
    completed_at: datetime
    approved: bool
    rejection_reason: str | None
    notes: str | None


class SubmissionRejectRequest(BaseModel):
    """Body for PATCH /submissions/{id}/reject."""

    reason: str = Field(min_length=1, max_length=2000)
