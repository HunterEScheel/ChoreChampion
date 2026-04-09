"""Submission endpoints: submit, list, reject, unreject."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, HTTPException, Query, status
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
from app.schemas.submission import (
    SubmissionCreateRequest,
    SubmissionRead,
    SubmissionRejectRequest,
)
from app.services.submission_rules import check_submission_eligibility

router = APIRouter(prefix="/submissions", tags=["submissions"])


def _http_error(status_code: int, code: str, detail: str) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={"code": code, "detail": detail},
    )


@router.post("", response_model=SubmissionRead, status_code=status.HTTP_201_CREATED)
async def create_submission(
    body: SubmissionCreateRequest,
    device: CurrentDevice,
    household: CurrentHousehold,
    member: ActiveMember,
    session: SessionDep,
) -> SubmissionRead:
    """Submit a completed chore.

    ``member_id`` comes from the ``X-Active-Member`` header via ``get_active_member``.
    Auto-approved per decision 4b; admins can retroactively reject.
    """
    chore = await session.get(Chore, body.chore_id)
    if chore is None:
        raise _http_error(
            status.HTTP_404_NOT_FOUND, "chore_not_found", "Chore not found"
        )

    eligibility = await check_submission_eligibility(
        session,
        chore=chore,
        member_id=member.member_id,
        household_timezone=household.timezone,
    )
    if not eligibility.ok:
        raise _http_error(
            status.HTTP_409_CONFLICT,
            eligibility.reason or "not_eligible",
            "Chore is not eligible for submission",
        )

    now = datetime.now(UTC)
    submission = ChoreSubmission(
        chore_id=chore.chore_id,
        member_id=member.member_id,
        device_id=device.device_id,
        household_id=household.household_id,
        completed_at=now,
        approved=True,
        notes=body.notes,
    )
    session.add(submission)
    await session.commit()
    await session.refresh(submission)
    return SubmissionRead.model_validate(submission)


@router.get("", response_model=list[SubmissionRead])
async def list_submissions(
    _admin: AdminDevice,
    household: CurrentHousehold,
    session: SessionDep,
    days: int = Query(default=7, ge=1, le=90),
    member_id: uuid.UUID | None = None,
    approved: bool | None = None,
) -> list[SubmissionRead]:
    """Admin lists submissions (default: last 7 days, all members, all statuses)."""
    since = datetime.now(UTC) - timedelta(days=days)
    filters = [
        ChoreSubmission.household_id == household.household_id,
        ChoreSubmission.completed_at >= since,
    ]
    if member_id is not None:
        filters.append(ChoreSubmission.member_id == member_id)
    if approved is not None:
        filters.append(ChoreSubmission.approved.is_(approved))

    stmt = (
        select(ChoreSubmission)
        .where(and_(*filters))
        .order_by(ChoreSubmission.completed_at.desc())
    )
    rows = (await session.execute(stmt)).scalars().all()
    return [SubmissionRead.model_validate(r) for r in rows]


@router.patch("/{submission_id}/reject", response_model=SubmissionRead)
async def reject_submission(
    submission_id: uuid.UUID,
    body: SubmissionRejectRequest,
    _admin: AdminDevice,
    household: CurrentHousehold,
    session: SessionDep,
) -> SubmissionRead:
    """Admin flips an auto-approved submission to ``approved=False`` with a reason."""
    submission = await session.get(ChoreSubmission, submission_id)
    if submission is None or submission.household_id != household.household_id:
        raise _http_error(
            status.HTTP_404_NOT_FOUND,
            "submission_not_found",
            "Submission not found",
        )
    submission.approved = False
    submission.rejection_reason = body.reason
    await session.commit()
    await session.refresh(submission)
    return SubmissionRead.model_validate(submission)


@router.patch("/{submission_id}/unreject", response_model=SubmissionRead)
async def unreject_submission(
    submission_id: uuid.UUID,
    _admin: AdminDevice,
    household: CurrentHousehold,
    session: SessionDep,
) -> SubmissionRead:
    """Undo a rejection — flip approved back to True, clear reason."""
    submission = await session.get(ChoreSubmission, submission_id)
    if submission is None or submission.household_id != household.household_id:
        raise _http_error(
            status.HTTP_404_NOT_FOUND,
            "submission_not_found",
            "Submission not found",
        )
    submission.approved = True
    submission.rejection_reason = None
    await session.commit()
    await session.refresh(submission)
    return SubmissionRead.model_validate(submission)
