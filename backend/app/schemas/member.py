"""Family member request/response schemas."""

from __future__ import annotations

from pydantic import BaseModel, Field


class MemberCreateRequest(BaseModel):
    """Body for POST /members (admin only)."""

    name: str = Field(min_length=1, max_length=255)


class MemberPatchRequest(BaseModel):
    """Body for PATCH /members/{id} (admin only)."""

    name: str = Field(min_length=1, max_length=255)
