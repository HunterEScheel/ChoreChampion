"""Submission eligibility rules.

The single gate that enforces decision 3c: "same chore, same member, same day"
regardless of cadence. Also enforces the cadence-specific window (weekly,
monthly) so that chores with longer cadences hide until the next window.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.chore import Chore
from app.models.chore_submission import ChoreSubmission
from app.services.cadence import window_for_cadence


@dataclass(frozen=True)
class EligibilityResult:
    """Outcome of an eligibility check."""

    ok: bool
    reason: str | None = None


async def check_submission_eligibility(
    session: AsyncSession,
    *,
    chore: Chore,
    member_id: uuid.UUID,
    household_timezone: str,
    now_utc: datetime | None = None,
) -> EligibilityResult:
    """Return an EligibilityResult for the given (chore, member) pair.

    Rejects if:
        - The chore is inactive
        - An approved submission already exists in the cadence window for this
          member (daily/weekly/monthly). For ``on_request`` chores, the window
          is still daily per decision 3c.
    """
    if not chore.active:
        return EligibilityResult(ok=False, reason="chore_inactive")

    now = now_utc if now_utc is not None else datetime.now(UTC)
    start_utc, end_utc = window_for_cadence(chore.cadence, now, household_timezone)

    stmt = select(ChoreSubmission.submission_id).where(
        and_(
            ChoreSubmission.chore_id == chore.chore_id,
            ChoreSubmission.member_id == member_id,
            ChoreSubmission.approved.is_(True),
            ChoreSubmission.completed_at >= start_utc,
            ChoreSubmission.completed_at < end_utc,
        )
    )
    existing = (await session.execute(stmt)).scalar_one_or_none()
    if existing is not None:
        return EligibilityResult(ok=False, reason="already_submitted")

    return EligibilityResult(ok=True)
