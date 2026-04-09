"""End-to-end integration tests.

These tests exercise the full HTTP stack against a real Postgres. They require
``docker compose up -d db`` to be running in ``backend/``. Unit tests in
``tests/unit`` do not need Docker and can always run.
"""

from __future__ import annotations

import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.chore import Chore
from app.models.difficulty_reward import DifficultyReward
from app.models.family_member import FamilyMember
from app.models.reward_category import RewardCategory

API = "/api/v1"


@pytest.mark.asyncio
async def test_healthz(client: AsyncClient) -> None:
    resp = await client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


@pytest.mark.asyncio
async def test_bootstrap_returns_jwt_and_makes_admin(client: AsyncClient) -> None:
    resp = await client.post(
        f"{API}/households",
        json={
            "household_name": "The Smiths",
            "timezone": "America/Chicago",
            "ssid_hash": None,
            "device_name": "Mom's iPhone",
        },
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["household"]["name"] == "The Smiths"
    assert body["household"]["timezone"] == "America/Chicago"
    assert body["device"]["is_admin"] is True
    assert isinstance(body["jwt"], str) and len(body["jwt"]) > 0


@pytest.mark.asyncio
async def test_me_endpoint_requires_token(client: AsyncClient) -> None:
    resp = await client.get(f"{API}/households/me")
    assert resp.status_code == 401
    assert resp.json()["code"] == "missing_token"


@pytest.mark.asyncio
async def test_full_happy_path(client: AsyncClient, db_session: AsyncSession) -> None:
    """Bootstrap -> add member + chore + reward mapping -> submit -> rewards."""
    # 1. Bootstrap household
    resp = await client.post(
        f"{API}/households",
        json={
            "household_name": "Smith",
            "timezone": "America/Chicago",
            "ssid_hash": None,
            "device_name": "iPad",
        },
    )
    assert resp.status_code == 201
    bootstrap = resp.json()
    jwt = bootstrap["jwt"]
    household_id = uuid.UUID(bootstrap["household"]["household_id"])
    auth_headers = {"Authorization": f"Bearer {jwt}"}

    # 2. Seed a family member + reward category + difficulty mapping + chore
    member = FamilyMember(household_id=household_id, name="Alice")
    category = RewardCategory(
        household_id=household_id, name="Screen Time", type="integer"
    )
    db_session.add_all([member, category])
    await db_session.flush()

    mapping = DifficultyReward(
        household_id=household_id,
        difficulty="easy",
        reward_category_id=category.reward_category_id,
        value=5.0,
    )
    chore = Chore(name="Make bed", difficulty="easy", cadence="daily", active=True)
    db_session.add_all([mapping, chore])
    await db_session.flush()

    member_id = member.member_id
    chore_id = chore.chore_id

    active_headers = {**auth_headers, "X-Active-Member": str(member_id)}

    # 3. List chores — should include "Make bed" with rewards
    resp = await client.get(f"{API}/chores", headers=active_headers)
    assert resp.status_code == 200, resp.text
    chores = resp.json()
    assert any(c["name"] == "Make bed" for c in chores)
    found = next(c for c in chores if c["name"] == "Make bed")
    assert found["rewards"].get("Screen Time") == 5.0

    # 4. Submit the chore
    resp = await client.post(
        f"{API}/submissions",
        headers=active_headers,
        json={"chore_id": str(chore_id), "notes": "Done!"},
    )
    assert resp.status_code == 201, resp.text
    submission = resp.json()
    assert submission["approved"] is True

    # 5. Second submit same day should fail with 409 already_submitted
    resp = await client.post(
        f"{API}/submissions",
        headers=active_headers,
        json={"chore_id": str(chore_id)},
    )
    assert resp.status_code == 409
    assert resp.json()["code"] == "already_submitted"

    # 6. Chore should now be filtered out of the available list
    resp = await client.get(f"{API}/chores", headers=active_headers)
    assert resp.status_code == 200
    names = [c["name"] for c in resp.json()]
    assert "Make bed" not in names

    # 7. Rewards should show 5 minutes of screen time for Alice
    resp = await client.get(f"{API}/rewards", headers=auth_headers)
    assert resp.status_code == 200
    payload = resp.json()
    alice = next(m for m in payload["members"] if m["name"] == "Alice")
    assert alice["totals"]["Screen Time"] == 5.0


@pytest.mark.asyncio
async def test_active_member_header_required_for_submit(
    client: AsyncClient,
) -> None:
    # Bootstrap first to get a token
    resp = await client.post(
        f"{API}/households",
        json={
            "household_name": "NoHeader",
            "timezone": "UTC",
            "ssid_hash": None,
            "device_name": "Phone",
        },
    )
    jwt = resp.json()["jwt"]

    resp = await client.post(
        f"{API}/submissions",
        headers={"Authorization": f"Bearer {jwt}"},
        json={"chore_id": str(uuid.uuid4())},
    )
    assert resp.status_code == 400
    assert resp.json()["code"] == "active_member_missing"


@pytest.mark.asyncio
async def test_non_admin_cannot_create_chore(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    # Admin bootstrap
    resp = await client.post(
        f"{API}/households",
        json={
            "household_name": "H",
            "timezone": "UTC",
            "ssid_hash": None,
            "device_name": "A",
        },
    )
    admin_jwt = resp.json()["jwt"]
    household_id = uuid.UUID(resp.json()["household"]["household_id"])

    # Admin creates a join token
    resp = await client.post(
        f"{API}/devices/join-tokens",
        headers={"Authorization": f"Bearer {admin_jwt}"},
    )
    assert resp.status_code == 201
    plain_token = resp.json()["token"]

    # Second device joins
    resp = await client.post(
        f"{API}/devices/join",
        json={
            "household_id": str(household_id),
            "ssid_hash": None,
            "join_token": plain_token,
            "device_name": "Kid tablet",
        },
    )
    assert resp.status_code == 201
    child_jwt = resp.json()["jwt"]

    # Child device tries to create a chore — should 403
    resp = await client.post(
        f"{API}/chores",
        headers={"Authorization": f"Bearer {child_jwt}"},
        json={"name": "Mow", "difficulty": "hard", "cadence": "weekly", "active": True},
    )
    assert resp.status_code == 403
    assert resp.json()["code"] == "admin_required"
