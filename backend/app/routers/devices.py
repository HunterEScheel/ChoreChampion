"""Device endpoints: join-token generation and device join."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import and_, select

from app.auth import (
    generate_device_hash,
    generate_join_token,
    hash_join_token,
    issue_device_jwt,
)
from app.config import get_settings
from app.dependencies import AdminDevice, SessionDep
from app.models.device import Device
from app.models.household import Household
from app.models.join_token import JoinToken
from app.schemas.device import (
    DeviceJoinRequest,
    DeviceJoinResponse,
    JoinTokenCreateResponse,
)

router = APIRouter(prefix="/devices", tags=["devices"])


def _http_error(status_code: int, code: str, detail: str) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={"code": code, "detail": detail},
    )


@router.post(
    "/join-tokens",
    response_model=JoinTokenCreateResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_join_token(
    admin: AdminDevice,
    session: SessionDep,
) -> JoinTokenCreateResponse:
    """Admin generates a short-lived join token for a new device.

    The plaintext token is returned exactly once; only its hash is stored.
    """
    settings = get_settings()
    plaintext, token_hash = generate_join_token()
    expires_at = datetime.now(UTC) + timedelta(minutes=settings.join_token_ttl_minutes)

    token_row = JoinToken(
        household_id=admin.household_id,
        token_hash=token_hash,
        expires_at=expires_at,
        created_by_device=admin.device_id,
    )
    session.add(token_row)
    await session.commit()

    return JoinTokenCreateResponse(token=plaintext, expires_at=expires_at)


@router.post(
    "/join",
    response_model=DeviceJoinResponse,
    status_code=status.HTTP_201_CREATED,
)
async def join_device(
    body: DeviceJoinRequest,
    session: SessionDep,
) -> DeviceJoinResponse:
    """SSID-primary, token-fallback device join.

    Decision 2a: if ``ssid_hash`` matches the household's registered SSID, the
    device is trusted. Otherwise a valid, unused, non-expired ``join_token`` is
    required.
    """
    household = await session.get(Household, body.household_id)
    if household is None:
        raise _http_error(
            status.HTTP_404_NOT_FOUND, "household_not_found", "Household not found"
        )

    authorized = False

    if (
        body.ssid_hash is not None
        and household.ssid_hash is not None
        and body.ssid_hash == household.ssid_hash
    ):
        authorized = True

    if not authorized:
        if body.join_token is None:
            raise _http_error(
                status.HTTP_401_UNAUTHORIZED,
                "ssid_mismatch",
                "SSID did not match and no join token provided",
            )
        token_hash = hash_join_token(body.join_token)
        stmt = select(JoinToken).where(
            and_(
                JoinToken.household_id == body.household_id,
                JoinToken.token_hash == token_hash,
                JoinToken.used_at.is_(None),
                JoinToken.expires_at > datetime.now(UTC),
            )
        )
        token_row = (await session.execute(stmt)).scalar_one_or_none()
        if token_row is None:
            raise _http_error(
                status.HTTP_401_UNAUTHORIZED,
                "join_token_invalid",
                "Join token is missing, expired, used, or invalid",
            )
        token_row.used_at = datetime.now(UTC)
        authorized = True

    device = Device(
        household_id=body.household_id,
        device_hash=generate_device_hash(),
        device_name=body.device_name,
        is_admin=False,
        active=True,
    )
    session.add(device)
    await session.commit()
    await session.refresh(device)

    jwt_token = issue_device_jwt(
        device_id=device.device_id,
        household_id=device.household_id,
        is_admin=False,
    )
    return DeviceJoinResponse(jwt=jwt_token)
