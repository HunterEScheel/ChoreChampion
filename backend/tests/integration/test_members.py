"""Integration tests for member CRUD endpoints."""

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
            "household_name": "MemberTest",
            "timezone": "UTC",
            "ssid_hash": None,
            "device_name": "Admin Phone",
        },
    )
    assert resp.status_code == 201
    body = resp.json()
    return body["jwt"], body["household"]["household_id"]


@pytest.mark.asyncio
async def test_create_member(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    resp = await client.post(
        f"{API}/members",
        headers=headers,
        json={"name": "Alice"},
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["name"] == "Alice"
    assert "member_id" in body
    assert "household_id" in body


@pytest.mark.asyncio
async def test_patch_member(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    # Create
    resp = await client.post(
        f"{API}/members", headers=headers, json={"name": "Bob"}
    )
    member_id = resp.json()["member_id"]

    # Patch
    resp = await client.patch(
        f"{API}/members/{member_id}",
        headers=headers,
        json={"name": "Robert"},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["name"] == "Robert"


@pytest.mark.asyncio
async def test_delete_member(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    # Create
    resp = await client.post(
        f"{API}/members", headers=headers, json={"name": "Charlie"}
    )
    member_id = resp.json()["member_id"]

    # Delete
    resp = await client.delete(
        f"{API}/members/{member_id}", headers=headers
    )
    assert resp.status_code == 204

    # Verify gone via /households/me
    resp = await client.get(f"{API}/households/me", headers=headers)
    names = [m["name"] for m in resp.json()["members"]]
    assert "Charlie" not in names


@pytest.mark.asyncio
async def test_patch_nonexistent_member_returns_404(client: AsyncClient) -> None:
    jwt, _ = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {jwt}"}

    resp = await client.patch(
        f"{API}/members/{uuid.uuid4()}",
        headers=headers,
        json={"name": "Ghost"},
    )
    assert resp.status_code == 404
    assert resp.json()["code"] == "member_not_found"


@pytest.mark.asyncio
async def test_non_admin_cannot_create_member(client: AsyncClient) -> None:
    jwt, household_id = await _bootstrap(client)
    admin_headers = {"Authorization": f"Bearer {jwt}"}

    # Create a join token
    resp = await client.post(
        f"{API}/devices/join-tokens", headers=admin_headers
    )
    plain_token = resp.json()["token"]

    # Non-admin device joins
    resp = await client.post(
        f"{API}/devices/join",
        json={
            "household_id": household_id,
            "ssid_hash": None,
            "join_token": plain_token,
            "device_name": "Kid tablet",
        },
    )
    child_jwt = resp.json()["jwt"]

    # Child tries to create member
    resp = await client.post(
        f"{API}/members",
        headers={"Authorization": f"Bearer {child_jwt}"},
        json={"name": "Sneaky"},
    )
    assert resp.status_code == 403
    assert resp.json()["code"] == "admin_required"
