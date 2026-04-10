"""Integration tests for reward category & mapping CRUD endpoints."""

from __future__ import annotations

import uuid

import pytest
from httpx import AsyncClient

API = "/api/v1"


async def _bootstrap(client: AsyncClient) -> tuple[str, str]:
    """Create household and return (jwt, household_id)."""
    resp = await client.post(
        f"{API}/households",
        json={
            "household_name": "RewardCfgTest",
            "timezone": "UTC",
            "ssid_hash": None,
            "device_name": "Admin",
        },
    )
    assert resp.status_code == 201
    body = resp.json()
    return body["jwt"], body["household"]["household_id"]


# ── Reward categories ──────────────────────────────────────────────


@pytest.mark.asyncio
async def test_create_and_list_categories(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    # Create two categories
    resp = await client.post(
        f"{API}/rewards/categories",
        headers=headers,
        json={"name": "Screen Time", "type": "integer"},
    )
    assert resp.status_code == 201, resp.text
    cat1 = resp.json()
    assert cat1["name"] == "Screen Time"
    assert cat1["type"] == "integer"

    resp = await client.post(
        f"{API}/rewards/categories",
        headers=headers,
        json={"name": "Cash", "type": "float"},
    )
    assert resp.status_code == 201

    # List
    resp = await client.get(f"{API}/rewards/categories", headers=headers)
    assert resp.status_code == 200
    cats = resp.json()
    names = [c["name"] for c in cats]
    assert "Cash" in names
    assert "Screen Time" in names


@pytest.mark.asyncio
async def test_patch_category(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    resp = await client.post(
        f"{API}/rewards/categories",
        headers=headers,
        json={"name": "Points", "type": "integer"},
    )
    cat_id = resp.json()["reward_category_id"]

    resp = await client.patch(
        f"{API}/rewards/categories/{cat_id}",
        headers=headers,
        json={"name": "Gold Stars"},
    )
    assert resp.status_code == 200
    assert resp.json()["name"] == "Gold Stars"
    assert resp.json()["type"] == "integer"  # unchanged


@pytest.mark.asyncio
async def test_delete_category(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    resp = await client.post(
        f"{API}/rewards/categories",
        headers=headers,
        json={"name": "Temp", "type": "boolean"},
    )
    cat_id = resp.json()["reward_category_id"]

    resp = await client.delete(
        f"{API}/rewards/categories/{cat_id}", headers=headers
    )
    assert resp.status_code == 204

    # Verify gone
    resp = await client.get(f"{API}/rewards/categories", headers=headers)
    ids = [c["reward_category_id"] for c in resp.json()]
    assert cat_id not in ids


@pytest.mark.asyncio
async def test_patch_nonexistent_category_returns_404(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    resp = await client.patch(
        f"{API}/rewards/categories/{uuid.uuid4()}",
        headers=headers,
        json={"name": "Ghost"},
    )
    assert resp.status_code == 404
    assert resp.json()["code"] == "category_not_found"


# ── Difficulty→reward mappings ─────────────────────────────────────


@pytest.mark.asyncio
async def test_bulk_upsert_and_list_mappings(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    # Create a category first
    resp = await client.post(
        f"{API}/rewards/categories",
        headers=headers,
        json={"name": "Screen Time", "type": "integer"},
    )
    cat_id = resp.json()["reward_category_id"]

    # Bulk upsert mappings
    mappings = [
        {"difficulty": "easy", "reward_category_id": cat_id, "value": 5.0},
        {"difficulty": "medium", "reward_category_id": cat_id, "value": 15.0},
        {"difficulty": "hard", "reward_category_id": cat_id, "value": 30.0},
    ]
    resp = await client.put(
        f"{API}/rewards/mappings", headers=headers, json=mappings
    )
    assert resp.status_code == 200, resp.text
    result = resp.json()
    assert len(result) == 3
    values = {r["difficulty"]: r["value"] for r in result}
    assert values["easy"] == 5.0
    assert values["medium"] == 15.0
    assert values["hard"] == 30.0

    # List mappings
    resp = await client.get(f"{API}/rewards/mappings", headers=headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 3


@pytest.mark.asyncio
async def test_bulk_upsert_replaces_existing_mappings(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    # Create category
    resp = await client.post(
        f"{API}/rewards/categories",
        headers=headers,
        json={"name": "Cash", "type": "float"},
    )
    cat_id = resp.json()["reward_category_id"]

    # First upsert
    await client.put(
        f"{API}/rewards/mappings",
        headers=headers,
        json=[
            {"difficulty": "easy", "reward_category_id": cat_id, "value": 1.0},
            {"difficulty": "hard", "reward_category_id": cat_id, "value": 5.0},
        ],
    )

    # Second upsert replaces all
    resp = await client.put(
        f"{API}/rewards/mappings",
        headers=headers,
        json=[
            {"difficulty": "medium", "reward_category_id": cat_id, "value": 2.5},
        ],
    )
    assert resp.status_code == 200
    result = resp.json()
    assert len(result) == 1
    assert result[0]["difficulty"] == "medium"
    assert result[0]["value"] == 2.5

    # Verify only 1 mapping remains
    resp = await client.get(f"{API}/rewards/mappings", headers=headers)
    assert len(resp.json()) == 1


@pytest.mark.asyncio
async def test_empty_mappings_clears_all(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    # Create category + mapping
    resp = await client.post(
        f"{API}/rewards/categories",
        headers=headers,
        json={"name": "Pts", "type": "integer"},
    )
    cat_id = resp.json()["reward_category_id"]

    await client.put(
        f"{API}/rewards/mappings",
        headers=headers,
        json=[{"difficulty": "easy", "reward_category_id": cat_id, "value": 1.0}],
    )

    # Clear by sending empty list
    resp = await client.put(
        f"{API}/rewards/mappings", headers=headers, json=[]
    )
    assert resp.status_code == 200
    assert resp.json() == []

    resp = await client.get(f"{API}/rewards/mappings", headers=headers)
    assert len(resp.json()) == 0
