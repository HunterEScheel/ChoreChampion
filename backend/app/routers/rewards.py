"""Reward endpoints: per-member totals + category & mapping CRUD."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.dependencies import AdminDevice, CurrentDevice, CurrentHousehold, SessionDep
from app.models.difficulty_reward import DifficultyReward
from app.models.reward_category import RewardCategory
from app.schemas.reward import (
    DifficultyMappingRead,
    DifficultyMappingUpsert,
    MemberRewardTotals,
    RewardCategoryCreateRequest,
    RewardCategoryPatchRequest,
    RewardCategoryRead,
    RewardsResponse,
)
from app.services.rewards import compute_household_rewards

router = APIRouter(prefix="/rewards", tags=["rewards"])


def _http_error(status_code: int, code: str, detail: str) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={"code": code, "detail": detail},
    )


# ── Per-member totals (existing) ───────────────────────────────────


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


# ── Reward categories CRUD ─────────────────────────────────────────


@router.get("/categories", response_model=list[RewardCategoryRead])
async def list_categories(
    _device: CurrentDevice,
    household: CurrentHousehold,
    session: SessionDep,
) -> list[RewardCategoryRead]:
    """List all reward categories for the current household."""
    stmt = (
        select(RewardCategory)
        .where(RewardCategory.household_id == household.household_id)
        .order_by(RewardCategory.name)
    )
    rows = (await session.execute(stmt)).scalars().all()
    return [RewardCategoryRead.model_validate(r) for r in rows]


@router.post(
    "/categories",
    response_model=RewardCategoryRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_category(
    body: RewardCategoryCreateRequest,
    admin: AdminDevice,
    session: SessionDep,
) -> RewardCategoryRead:
    """Admin creates a reward category for the household."""
    category = RewardCategory(
        household_id=admin.household_id,
        name=body.name,
        type=body.type,
    )
    session.add(category)
    await session.commit()
    await session.refresh(category)
    return RewardCategoryRead.model_validate(category)


@router.patch("/categories/{category_id}", response_model=RewardCategoryRead)
async def patch_category(
    category_id: uuid.UUID,
    body: RewardCategoryPatchRequest,
    admin: AdminDevice,
    session: SessionDep,
) -> RewardCategoryRead:
    """Admin updates a reward category."""
    stmt = select(RewardCategory).where(
        RewardCategory.reward_category_id == category_id,
        RewardCategory.household_id == admin.household_id,
    )
    category = (await session.execute(stmt)).scalar_one_or_none()
    if category is None:
        raise _http_error(
            status.HTTP_404_NOT_FOUND,
            "category_not_found",
            "Reward category not found in your household",
        )

    if body.name is not None:
        category.name = body.name
    if body.type is not None:
        category.type = body.type

    await session.commit()
    await session.refresh(category)
    return RewardCategoryRead.model_validate(category)


@router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: uuid.UUID,
    admin: AdminDevice,
    session: SessionDep,
) -> None:
    """Admin deletes a reward category (cascades to mappings)."""
    stmt = select(RewardCategory).where(
        RewardCategory.reward_category_id == category_id,
        RewardCategory.household_id == admin.household_id,
    )
    category = (await session.execute(stmt)).scalar_one_or_none()
    if category is None:
        raise _http_error(
            status.HTTP_404_NOT_FOUND,
            "category_not_found",
            "Reward category not found in your household",
        )
    await session.delete(category)
    await session.commit()


# ── Difficulty→reward mappings CRUD ────────────────────────────────


@router.get("/mappings", response_model=list[DifficultyMappingRead])
async def list_mappings(
    _device: CurrentDevice,
    household: CurrentHousehold,
    session: SessionDep,
) -> list[DifficultyMappingRead]:
    """List all difficulty→reward mappings for the current household."""
    stmt = (
        select(DifficultyReward)
        .where(DifficultyReward.household_id == household.household_id)
        .order_by(DifficultyReward.difficulty, DifficultyReward.reward_category_id)
    )
    rows = (await session.execute(stmt)).scalars().all()
    return [DifficultyMappingRead.model_validate(r) for r in rows]


@router.put("/mappings", response_model=list[DifficultyMappingRead])
async def bulk_upsert_mappings(
    body: list[DifficultyMappingUpsert],
    admin: AdminDevice,
    session: SessionDep,
) -> list[DifficultyMappingRead]:
    """Admin replaces all difficulty→reward mappings for the household.

    Deletes existing mappings and inserts the provided set.  This is simpler
    than individual CRUD and matches the admin UI pattern of "save all at once".
    """
    # Delete all existing mappings for this household
    stmt = select(DifficultyReward).where(
        DifficultyReward.household_id == admin.household_id,
    )
    existing = (await session.execute(stmt)).scalars().all()
    for row in existing:
        await session.delete(row)
    await session.flush()

    # Insert new mappings
    new_rows: list[DifficultyReward] = []
    for item in body:
        mapping = DifficultyReward(
            household_id=admin.household_id,
            difficulty=item.difficulty,
            reward_category_id=item.reward_category_id,
            value=item.value,
        )
        session.add(mapping)
        new_rows.append(mapping)

    await session.commit()
    for row in new_rows:
        await session.refresh(row)

    return [DifficultyMappingRead.model_validate(r) for r in new_rows]
