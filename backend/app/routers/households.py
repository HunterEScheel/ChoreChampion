"""Household endpoints."""

from __future__ import annotations

from fastapi import APIRouter, status
from sqlalchemy import select

from app.auth import generate_device_hash, issue_device_jwt
from app.dependencies import CurrentDevice, CurrentHousehold, SessionDep
from app.models.device import Device
from app.models.family_member import FamilyMember
from app.models.household import Household
from app.schemas.household import (
    BootstrapResponse,
    DeviceRead,
    HouseholdCreateRequest,
    HouseholdMeResponse,
    HouseholdRead,
    MemberRead,
)

router = APIRouter(prefix="/households", tags=["households"])


@router.post("", response_model=BootstrapResponse, status_code=status.HTTP_201_CREATED)
async def create_household(
    body: HouseholdCreateRequest,
    session: SessionDep,
) -> BootstrapResponse:
    """Bootstrap: create household + first admin device + return JWT.

    No auth required — this is the entry point for a brand-new family.
    """
    household = Household(
        name=body.household_name,
        timezone=body.timezone,
        ssid_hash=body.ssid_hash,
    )
    session.add(household)
    await session.flush()  # populate household.household_id

    device = Device(
        household_id=household.household_id,
        device_hash=generate_device_hash(),
        device_name=body.device_name,
        is_admin=True,
        active=True,
    )
    session.add(device)
    await session.flush()

    await session.commit()
    await session.refresh(household)
    await session.refresh(device)

    token = issue_device_jwt(
        device_id=device.device_id,
        household_id=household.household_id,
        is_admin=True,
    )

    return BootstrapResponse(
        household=HouseholdRead.model_validate(household),
        device=DeviceRead.model_validate(device),
        jwt=token,
    )


@router.get("/me", response_model=HouseholdMeResponse)
async def read_my_household(
    household: CurrentHousehold,
    _device: CurrentDevice,
    session: SessionDep,
) -> HouseholdMeResponse:
    """Return the household of the calling device, with its members."""
    stmt = (
        select(FamilyMember)
        .where(FamilyMember.household_id == household.household_id)
        .order_by(FamilyMember.name)
    )
    members = (await session.execute(stmt)).scalars().all()
    return HouseholdMeResponse(
        household=HouseholdRead.model_validate(household),
        members=[MemberRead.model_validate(m) for m in members],
    )
