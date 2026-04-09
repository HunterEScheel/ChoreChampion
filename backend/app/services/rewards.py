"""Reward aggregation service.

Live-join implementation per decision 5a: totals are computed by joining
``chore_submissions -> chores -> difficulty_rewards`` at query time, so any
edit to the reward table retroactively recalculates history.
"""

from __future__ import annotations

import uuid
from collections import defaultdict
from typing import cast

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.chore import Chore
from app.models.chore_submission import ChoreSubmission
from app.models.difficulty_reward import DifficultyReward
from app.models.family_member import FamilyMember
from app.models.reward_category import RewardCategory


async def compute_household_rewards(
    session: AsyncSession,
    *,
    household_id: uuid.UUID,
) -> list[dict]:
    """Return per-member reward totals for a household.

    Each list item has shape::

        {
            "member_id": UUID,
            "name": str,
            "totals": {"Screen Time": 35.0, "Cash": 3.5},
        }

    Members with no approved submissions still appear with an empty ``totals`` dict.
    """
    # 1. Pull every member in the household so members with no submissions still
    #    show up in the response.
    members_stmt = (
        select(FamilyMember.member_id, FamilyMember.name)
        .where(FamilyMember.household_id == household_id)
        .order_by(FamilyMember.name)
    )
    member_rows = (await session.execute(members_stmt)).all()

    # 2. Join submissions -> chores -> difficulty_rewards -> reward_categories
    #    scoped to this household and approved submissions only.
    join_stmt = (
        select(
            ChoreSubmission.member_id,
            RewardCategory.name.label("category_name"),
            DifficultyReward.value,
        )
        .join(Chore, Chore.chore_id == ChoreSubmission.chore_id)
        .join(
            DifficultyReward,
            and_(
                DifficultyReward.household_id == household_id,
                DifficultyReward.difficulty == Chore.difficulty,
            ),
        )
        .join(
            RewardCategory,
            RewardCategory.reward_category_id == DifficultyReward.reward_category_id,
        )
        .where(
            and_(
                ChoreSubmission.household_id == household_id,
                ChoreSubmission.approved.is_(True),
            )
        )
    )
    join_rows = (await session.execute(join_stmt)).all()

    # 3. Aggregate in Python — the result set is bounded by household size.
    totals_by_member: dict[uuid.UUID, dict[str, float]] = defaultdict(
        lambda: defaultdict(float)
    )
    for row in join_rows:
        member_id = cast(uuid.UUID, row.member_id)
        category_name = cast(str, row.category_name)
        value = cast(float, row.value)
        totals_by_member[member_id][category_name] += value

    return [
        {
            "member_id": row.member_id,
            "name": row.name,
            "totals": dict(totals_by_member.get(row.member_id, {})),
        }
        for row in member_rows
    ]
