"""Top-level conftest.

Shared pytest configuration lives here. Integration-specific fixtures (which
require ``pytest-asyncio``, a running Postgres, and ``httpx``) are scoped to
``tests/integration/conftest.py`` so unit tests can run without those deps.
"""
