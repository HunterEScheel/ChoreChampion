"""Family member endpoints: create, update, delete."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.dependencies import AdminDevice, SessionDep
from app.models.family_member import FamilyMember
from app.schemas.household import MemberRead
from app.schemas.member import MemberCreateRequest, MemberPatchRequest

router = APIRouter(prefix="/members", tags=["members"])


def _http_error(status_code: int, code: str, detail: str) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={"code": code, "detail": detail},
    )


async def _get_member_or_404(
    session, member_id: uuid.UUID, household_id: uuid.UUID
) -> FamilyMember:
    """Fetch a member ensuring it belongs to the admin's household."""
    stmt = select(FamilyMember).where(
        FamilyMember.member_id == member_id,
        FamilyMember.household_id == household_id,
    )
    member = (await session.execute(stmt)).scalar_one_or_none()
    if member is None:
        raise _http_error(
            status.HTTP_404_NOT_FOUND,
            "member_not_found",
            "Member not found in your household",
        )
    return member


@router.post("", response_model=MemberRead, status_code=status.HTTP_201_CREATED)
async def create_member(
    body: MemberCreateRequest,
    admin: AdminDevice,
    session: SessionDep,
) -> MemberRead:
    """Admin adds a family member to the household."""
    member = FamilyMember(
        household_id=admin.household_id,
        name=body.name,
    )
    session.add(member)
    await session.commit()
    await session.refresh(member)
    return MemberRead.model_validate(member)


@router.patch("/{member_id}", response_model=MemberRead)
async def patch_member(
    member_id: uuid.UUID,
    body: MemberPatchRequest,
    admin: AdminDevice,
    session: SessionDep,
) -> MemberRead:
    """Admin renames a family member."""
    member = await _get_member_or_404(session, member_id, admin.household_id)
    member.name = body.name
    await session.commit()
    await session.refresh(member)
    return MemberRead.model_validate(member)


@router.delete("/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_member(
    member_id: uuid.UUID,
    admin: AdminDevice,
    session: SessionDep,
) -> None:
    """Admin removes a family member from the household."""
    member = await _get_member_or_404(session, member_id, admin.household_id)
    await session.delete(member)
    await session.commit()
