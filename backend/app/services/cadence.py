"""Cadence window math.

Pure functions — no database, no I/O. Given a cadence string, "now" in UTC, and
an IANA time zone name, returns the ``(start_utc, end_utc)`` half-open interval
for the window that contains "now" in the household's local time.

All windows are half-open: ``start_utc <= instant < end_utc``.

DST handling: wall-clock arithmetic is always done via ``date`` objects and
``datetime.combine(date, time, tzinfo=tz)``. Never add ``timedelta(days=1)`` to
a tz-aware datetime — that adds 24 real hours, which skips or doubles an hour
during DST transitions.
"""

from __future__ import annotations

from datetime import UTC, date, datetime, time, timedelta
from typing import Final
from zoneinfo import ZoneInfo

VALID_CADENCES: Final = frozenset({"daily", "weekly", "monthly", "on_request"})


def _local_midnight(d: date, tz: ZoneInfo) -> datetime:
    """Return a timezone-aware datetime for 00:00 local on the given date."""
    return datetime.combine(d, time(0, 0), tzinfo=tz)


def _daily_window(local: datetime, tz: ZoneInfo) -> tuple[datetime, datetime]:
    today = local.date()
    start = _local_midnight(today, tz)
    end = _local_midnight(today + timedelta(days=1), tz)
    return start, end


def _weekly_window(local: datetime, tz: ZoneInfo) -> tuple[datetime, datetime]:
    # ISO week: Monday == 0
    monday = local.date() - timedelta(days=local.weekday())
    start = _local_midnight(monday, tz)
    end = _local_midnight(monday + timedelta(days=7), tz)
    return start, end


def _monthly_window(local: datetime, tz: ZoneInfo) -> tuple[datetime, datetime]:
    first_of_month = local.date().replace(day=1)
    start = _local_midnight(first_of_month, tz)
    if first_of_month.month == 12:
        next_month = first_of_month.replace(year=first_of_month.year + 1, month=1)
    else:
        next_month = first_of_month.replace(month=first_of_month.month + 1)
    end = _local_midnight(next_month, tz)
    return start, end


def window_for_cadence(
    cadence: str,
    now_utc: datetime,
    tz_name: str,
) -> tuple[datetime, datetime]:
    """Return ``(start_utc, end_utc)`` of the cadence window containing ``now_utc``.

    Args:
        cadence: One of ``daily``, ``weekly``, ``monthly``, ``on_request``.
        now_utc: Current instant. Must be timezone-aware (UTC).
        tz_name: IANA time zone name for the household (e.g. ``America/Chicago``).

    Raises:
        ValueError: If ``cadence`` is unknown or ``now_utc`` is naive.

    Notes:
        - ``on_request`` uses the same per-day window as ``daily`` per decision 3c:
          "cadence controls visibility, not per-day floor."
        - Windows are half-open: the end is *exclusive*.
    """
    if cadence not in VALID_CADENCES:
        raise ValueError(f"Unknown cadence: {cadence!r}")
    if now_utc.tzinfo is None:
        raise ValueError("now_utc must be timezone-aware")

    tz = ZoneInfo(tz_name)
    local = now_utc.astimezone(tz)

    if cadence in ("daily", "on_request"):
        start_local, end_local = _daily_window(local, tz)
    elif cadence == "weekly":
        start_local, end_local = _weekly_window(local, tz)
    else:  # monthly
        start_local, end_local = _monthly_window(local, tz)

    return start_local.astimezone(UTC), end_local.astimezone(UTC)
