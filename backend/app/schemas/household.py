"""Household-related request/response schemas."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class HouseholdCreateRequest(BaseModel):
    """Body for POST /households (bootstrap, no auth)."""

    household_name: str = Field(min_length=1, max_length=255)
    timezone: str = Field(
        default="UTC",
        max_length=64,
        description="IANA time zone, e.g. 'America/Chicago'.",
    )
    ssid_hash: str | None = Field(default=None, max_length=128)
    device_name: str = Field(min_length=1, max_length=120)


class HouseholdRead(BaseModel):
    """Public view of a household."""

    model_config = ConfigDict(from_attributes=True)

    household_id: uuid.UUID
    name: str
    timezone: str
    created_at: datetime


class DeviceRead(BaseModel):
    """Public view of a device."""

    model_config = ConfigDict(from_attributes=True)

    device_id: uuid.UUID
    household_id: uuid.UUID
    device_name: str | None
    is_admin: bool
    created_at: datetime


class BootstrapResponse(BaseModel):
    """Response for POST /households — contains the created household, device, and JWT."""

    household: HouseholdRead
    device: DeviceRead
    jwt: str


class MemberRead(BaseModel):
    """Public view of a family member."""

    model_config = ConfigDict(from_attributes=True)

    member_id: uuid.UUID
    household_id: uuid.UUID
    name: str


class HouseholdMeResponse(BaseModel):
    """Response for GET /households/me."""

    household: HouseholdRead
    members: list[MemberRead]
