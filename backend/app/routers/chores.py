"""Chore endpoints: list, create, update."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import and_, select

from app.dependencies import (
    ActiveMember,
    AdminDevice,
    CurrentDevice,
    CurrentHousehold,
    SessionDep,
)
from app.models.chore import Chore
from app.models.chore_submission import ChoreSubmission
from app.models.difficulty_reward import DifficultyReward
from app.models.reward_category import RewardCategory
from app.schemas.chore import (
    ChoreCreateRequest,
    ChorePatchRequest,
    ChoreRead,
    ChoreWithRewards,
)
from app.services.cadence import window_for_cadence

router = APIRouter(prefix="/chores", tags=["chores"])


def _http_error(status_code: int, code: str, detail: str) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={"code": code, "detail": detail},
    )


async def _rewards_map_for_household(
    session, household_id: uuid.UUID
) -> dict[str, dict[str, float]]:
    """Return ``{difficulty: {category_name: value}}`` for the household."""
    stmt = (
        select(
            DifficultyReward.difficulty,
            RewardCategory.name.label("category_name"),
            DifficultyReward.value,
        )
        .join(
            RewardCategory,
            RewardCategory.reward_category_id == DifficultyReward.reward_category_id,
        )
        .where(DifficultyReward.household_id == household_id)
    )
    rows = (await session.execute(stmt)).all()
    result: dict[str, dict[str, float]] = {}
    for row in rows:
        result.setdefault(row.difficulty, {})[row.category_name] = float(row.value)
    return result


@router.get("", response_model=list[ChoreWithRewards])
async def list_available_chores(
    _device: CurrentDevice,
    member: ActiveMember,
    household: CurrentHousehold,
    session: SessionDep,
) -> list[ChoreWithRewards]:
    """List chores available for the active member right now.

    Filters out chores already approved-submitted by this member within the
    chore's cadence window (see services/cadence.py).
    """
    all_active = (
        (await session.execute(select(Chore).where(Chore.active.is_(True))))
        .scalars()
        .all()
    )

    now = datetime.now(UTC)
    rewards_map = await _rewards_map_for_household(session, household.household_id)

    available: list[ChoreWithRewards] = []
    for chore in all_active:
        start_utc, end_utc = window_for_cadence(chore.cadence, now, household.timezone)
        existing_stmt = select(ChoreSubmission.submission_id).where(
            and_(
                ChoreSubmission.chore_id == chore.chore_id,
                ChoreSubmission.member_id == member.member_id,
                ChoreSubmission.approved.is_(True),
                ChoreSubmission.completed_at >= start_utc,
                ChoreSubmission.completed_at < end_utc,
            )
        )
        already_done = (await session.execute(existing_stmt)).scalar_one_or_none()
        if already_done is not None:
            continue

        available.append(
            ChoreWithRewards(
                chore_id=chore.chore_id,
                name=chore.name,
                difficulty=chore.difficulty,  # type: ignore[arg-type]
                cadence=chore.cadence,  # type: ignore[arg-type]
                active=chore.active,
                created_at=chore.created_at,
                rewards=rewards_map.get(chore.difficulty, {}),
            )
        )

    return available


@router.post("", response_model=ChoreRead, status_code=status.HTTP_201_CREATED)
async def create_chore(
    body: ChoreCreateRequest,
    _admin: AdminDevice,
    session: SessionDep,
) -> ChoreRead:
    """Admin creates a new chore template."""
    chore = Chore(
        name=body.name,
        difficulty=body.difficulty,
        cadence=body.cadence,
        active=body.active,
    )
    session.add(chore)
    await session.commit()
    await session.refresh(chore)
    return ChoreRead.model_validate(chore)


@router.patch("/{chore_id}", response_model=ChoreRead)
async def patch_chore(
    chore_id: uuid.UUID,
    body: ChorePatchRequest,
    _admin: AdminDevice,
    session: SessionDep,
) -> ChoreRead:
    """Admin updates a chore (name/difficulty/cadence/active)."""
    chore = await session.get(Chore, chore_id)
    if chore is None:
        raise _http_error(status.HTTP_404_NOT_FOUND, "chore_not_found", "Chore not found")

    if body.name is not None:
        chore.name = body.name
    if body.difficulty is not None:
        chore.difficulty = body.difficulty
    if body.cadence is not None:
        chore.cadence = body.cadence
    if body.active is not None:
        chore.active = body.active

    await session.commit()
    await session.refresh(chore)
    return ChoreRead.model_validate(chore)
