"""Device + join token request/response schemas."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class JoinTokenCreateResponse(BaseModel):
    """Plaintext token returned once to the admin after POST /devices/join-tokens."""

    token: str
    expires_at: datetime


class DeviceJoinRequest(BaseModel):
    """Body for POST /devices/join (SSID-primary, token fallback)."""

    household_id: uuid.UUID
    ssid_hash: str | None = Field(default=None, max_length=128)
    join_token: str | None = Field(default=None, max_length=128)
    device_name: str = Field(min_length=1, max_length=120)


class DeviceJoinResponse(BaseModel):
    """Response for POST /devices/join — JWT only per decision 2c."""

    jwt: str
