"""Reward response schemas."""

from __future__ import annotations

import uuid

from pydantic import BaseModel


class MemberRewardTotals(BaseModel):
    """Per-member totals across all approved submissions."""

    member_id: uuid.UUID
    name: str
    totals: dict[str, float]


class RewardsResponse(BaseModel):
    """Response for GET /rewards."""

    members: list[MemberRewardTotals]
