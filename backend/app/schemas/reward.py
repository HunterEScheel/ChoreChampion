"""Reward response schemas."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

RewardType = Literal["integer", "float", "boolean"]
Difficulty = Literal["easy", "medium", "hard", "flexible"]


# ── Totals (existing) ──────────────────────────────────────────────


class MemberRewardTotals(BaseModel):
    """Per-member totals across all approved submissions."""

    member_id: uuid.UUID
    name: str
    totals: dict[str, float]


class RewardsResponse(BaseModel):
    """Response for GET /rewards."""

    members: list[MemberRewardTotals]


# ── Reward category CRUD ───────────────────────────────────────────


class RewardCategoryCreateRequest(BaseModel):
    """Body for POST /rewards/categories."""

    name: str = Field(min_length=1, max_length=255)
    type: RewardType


class RewardCategoryPatchRequest(BaseModel):
    """Body for PATCH /rewards/categories/{id}."""

    name: str | None = Field(default=None, min_length=1, max_length=255)
    type: RewardType | None = None


class RewardCategoryRead(BaseModel):
    """Public view of a reward category."""

    model_config = ConfigDict(from_attributes=True)

    reward_category_id: uuid.UUID
    household_id: uuid.UUID
    name: str
    type: str
    created_at: datetime


# ── Difficulty→reward mapping CRUD ─────────────────────────────────


class DifficultyMappingUpsert(BaseModel):
    """Single item in the bulk PUT /rewards/mappings body."""

    difficulty: Difficulty
    reward_category_id: uuid.UUID
    value: float


class DifficultyMappingRead(BaseModel):
    """Public view of a difficulty→reward mapping."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    household_id: uuid.UUID
    difficulty: str
    reward_category_id: uuid.UUID
    value: float
    created_at: datetime
