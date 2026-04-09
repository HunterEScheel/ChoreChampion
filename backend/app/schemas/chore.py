"""Chore request/response schemas."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

Difficulty = Literal["easy", "medium", "hard", "flexible"]
Cadence = Literal["daily", "weekly", "monthly", "on_request"]


class ChoreCreateRequest(BaseModel):
    """Body for POST /chores (admin only)."""

    name: str = Field(min_length=1, max_length=255)
    difficulty: Difficulty
    cadence: Cadence
    active: bool = True


class ChorePatchRequest(BaseModel):
    """Body for PATCH /chores/{id}."""

    name: str | None = Field(default=None, min_length=1, max_length=255)
    difficulty: Difficulty | None = None
    cadence: Cadence | None = None
    active: bool | None = None


class RewardsMap(BaseModel):
    """Live-joined reward values for a chore's difficulty tier."""

    # Keys are reward-category names (e.g. "Screen Time", "Cash").
    # Values are floats (type coercion to int/bool happens in Flutter).
    values: dict[str, float]


class ChoreRead(BaseModel):
    """Public view of a chore, optionally annotated with live rewards."""

    model_config = ConfigDict(from_attributes=True)

    chore_id: uuid.UUID
    name: str
    difficulty: Difficulty
    cadence: Cadence
    active: bool
    created_at: datetime


class ChoreWithRewards(ChoreRead):
    """Chore read model with rewards map attached."""

    rewards: dict[str, float] = Field(default_factory=dict)
