"""FastAPI dependencies: auth, admin gate, active member resolver."""

from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import AuthError, decode_device_jwt
from app.database import get_session
from app.models.device import Device
from app.models.family_member import FamilyMember
from app.models.household import Household

# auto_error=False so we can return our own envelope with a code field.
_bearer_scheme = HTTPBearer(auto_error=False)


def _http_error(status_code: int, code: str, detail: str) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={"code": code, "detail": detail},
    )


SessionDep = Annotated[AsyncSession, Depends(get_session)]


async def get_current_device(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(_bearer_scheme)
    ],
    session: SessionDep,
) -> Device:
    """Resolve the current device from the Authorization header."""
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise _http_error(
            status.HTTP_401_UNAUTHORIZED, "missing_token", "Bearer token required"
        )

    try:
        claims = decode_device_jwt(credentials.credentials)
    except AuthError as exc:
        raise _http_error(
            status.HTTP_401_UNAUTHORIZED, str(exc), "Invalid or expired token"
        ) from exc

    device = await session.get(Device, claims.device_id)
    if device is None or not device.active:
        raise _http_error(
            status.HTTP_401_UNAUTHORIZED, "device_revoked", "Device is not active"
        )
    return device


CurrentDevice = Annotated[Device, Depends(get_current_device)]


async def require_admin(device: CurrentDevice) -> Device:
    """Admin gate — 403 if device is not an admin."""
    if not device.is_admin:
        raise _http_error(
            status.HTTP_403_FORBIDDEN,
            "admin_required",
            "This endpoint requires an admin device",
        )
    return device


AdminDevice = Annotated[Device, Depends(require_admin)]


async def get_household(
    device: CurrentDevice,
    session: SessionDep,
) -> Household:
    """Resolve the household the current device belongs to."""
    household = await session.get(Household, device.household_id)
    if household is None:
        raise _http_error(
            status.HTTP_404_NOT_FOUND,
            "household_not_found",
            "Household for current device not found",
        )
    return household


CurrentHousehold = Annotated[Household, Depends(get_household)]


async def get_active_member(
    device: CurrentDevice,
    session: SessionDep,
    x_active_member: Annotated[str | None, Header(alias="X-Active-Member")] = None,
) -> FamilyMember:
    """Resolve the member the device is currently acting as (via X-Active-Member header)."""
    if x_active_member is None:
        raise _http_error(
            status.HTTP_400_BAD_REQUEST,
            "active_member_missing",
            "X-Active-Member header is required",
        )
    try:
        member_uuid = uuid.UUID(x_active_member)
    except ValueError as exc:
        raise _http_error(
            status.HTTP_400_BAD_REQUEST,
            "active_member_missing",
            "X-Active-Member header is not a valid UUID",
        ) from exc

    stmt = select(FamilyMember).where(FamilyMember.member_id == member_uuid)
    member = (await session.execute(stmt)).scalar_one_or_none()

    if member is None:
        raise _http_error(
            status.HTTP_403_FORBIDDEN,
            "member_not_in_household",
            "Active member not found",
        )
    if member.household_id != device.household_id:
        raise _http_error(
            status.HTTP_403_FORBIDDEN,
            "member_not_in_household",
            "Active member belongs to a different household",
        )
    return member


ActiveMember = Annotated[FamilyMember, Depends(get_active_member)]
