"""Reward endpoint: per-member totals."""

from __future__ import annotations

from fastapi import APIRouter

from app.dependencies import CurrentDevice, CurrentHousehold, SessionDep
from app.schemas.reward import MemberRewardTotals, RewardsResponse
from app.services.rewards import compute_household_rewards

router = APIRouter(prefix="/rewards", tags=["rewards"])


@router.get("", response_model=RewardsResponse)
async def get_rewards(
    _device: CurrentDevice,
    household: CurrentHousehold,
    session: SessionDep,
) -> RewardsResponse:
    """Return per-member reward totals for the current household."""
    rows = await compute_household_rewards(
        session, household_id=household.household_id
    )
    members = [
        MemberRewardTotals(
            member_id=row["member_id"],
            name=row["name"],
            totals=row["totals"],
        )
        for row in rows
    ]
    return RewardsResponse(members=members)
