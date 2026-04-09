"""JWT issue + verify helpers.

The brainstorm plan mentions Supabase Auth, but for v1 we issue our own JWTs
signed with a shared secret (HS256). The Supabase swap is a drop-in later —
replace these helpers with JWKS verification against the Supabase project.

Tokens carry three custom claims:

    - ``device_id``   (UUID as string)
    - ``household_id`` (UUID as string)
    - ``is_admin``    (bool)
"""

from __future__ import annotations

import hashlib
import secrets
import uuid
from datetime import UTC, datetime, timedelta

from jose import JWTError, jwt
from pydantic import BaseModel

from app.config import get_settings


class TokenClaims(BaseModel):
    """Decoded JWT claims we rely on."""

    device_id: uuid.UUID
    household_id: uuid.UUID
    is_admin: bool
    exp: int


class AuthError(Exception):
    """Raised when a JWT is invalid, expired, or missing required claims."""


def issue_device_jwt(
    *,
    device_id: uuid.UUID,
    household_id: uuid.UUID,
    is_admin: bool,
) -> str:
    """Mint a signed JWT for a device."""
    settings = get_settings()
    expire = datetime.now(UTC) + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {
        "device_id": str(device_id),
        "household_id": str(household_id),
        "is_admin": is_admin,
        "exp": int(expire.timestamp()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_device_jwt(token: str) -> TokenClaims:
    """Decode and validate a JWT, returning its claims."""
    settings = get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
    except JWTError as exc:
        raise AuthError("invalid_token") from exc

    try:
        return TokenClaims(
            device_id=uuid.UUID(payload["device_id"]),
            household_id=uuid.UUID(payload["household_id"]),
            is_admin=bool(payload["is_admin"]),
            exp=int(payload["exp"]),
        )
    except (KeyError, ValueError, TypeError) as exc:
        raise AuthError("malformed_claims") from exc


# ---------------------------------------------------------------------------
# Join tokens — short-lived, single-use random strings
# ---------------------------------------------------------------------------


def generate_join_token() -> tuple[str, str]:
    """Return a ``(plaintext, sha256_hex)`` pair for a new join token."""
    plaintext = secrets.token_urlsafe(32)
    token_hash = hashlib.sha256(plaintext.encode("utf-8")).hexdigest()
    return plaintext, token_hash


def hash_join_token(plaintext: str) -> str:
    """Hash a join token for lookup in the database."""
    return hashlib.sha256(plaintext.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# Device hash — opaque identifier for a registered device
# ---------------------------------------------------------------------------


def generate_device_hash() -> str:
    """Return an opaque hash stored in ``devices.device_hash``."""
    return hashlib.sha256(secrets.token_bytes(32)).hexdigest()
