"""Tests for services/cadence.py — the only service that runs without a DB."""

from __future__ import annotations

from datetime import UTC, datetime
from zoneinfo import ZoneInfo

import pytest

from app.services.cadence import VALID_CADENCES, window_for_cadence

CHICAGO = "America/Chicago"
TOKYO = "Asia/Tokyo"
UTC_TZ = "UTC"


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------


def test_unknown_cadence_raises() -> None:
    with pytest.raises(ValueError, match="Unknown cadence"):
        window_for_cadence("yearly", datetime(2026, 4, 9, tzinfo=UTC), CHICAGO)


def test_naive_datetime_raises() -> None:
    with pytest.raises(ValueError, match="timezone-aware"):
        window_for_cadence("daily", datetime(2026, 4, 9), CHICAGO)


def test_valid_cadences_set() -> None:
    assert VALID_CADENCES == {"daily", "weekly", "monthly", "on_request"}


# ---------------------------------------------------------------------------
# Daily
# ---------------------------------------------------------------------------


def test_daily_window_chicago_afternoon() -> None:
    # 2026-04-09 15:00 UTC == 10:00 America/Chicago (CDT, UTC-5)
    now = datetime(2026, 4, 9, 15, 0, tzinfo=UTC)
    start, end = window_for_cadence("daily", now, CHICAGO)
    # Local day = 2026-04-09, midnight CDT = 05:00 UTC
    assert start == datetime(2026, 4, 9, 5, 0, tzinfo=UTC)
    assert end == datetime(2026, 4, 10, 5, 0, tzinfo=UTC)
    assert start <= now < end


def test_daily_window_chicago_just_after_local_midnight() -> None:
    # 2026-04-09 05:30 UTC == 00:30 America/Chicago CDT
    now = datetime(2026, 4, 9, 5, 30, tzinfo=UTC)
    start, end = window_for_cadence("daily", now, CHICAGO)
    assert start == datetime(2026, 4, 9, 5, 0, tzinfo=UTC)
    assert end == datetime(2026, 4, 10, 5, 0, tzinfo=UTC)


def test_daily_window_chicago_just_before_local_midnight() -> None:
    # 2026-04-09 04:59 UTC == 2026-04-08 23:59 CDT — still "yesterday" locally
    now = datetime(2026, 4, 9, 4, 59, tzinfo=UTC)
    start, end = window_for_cadence("daily", now, CHICAGO)
    assert start == datetime(2026, 4, 8, 5, 0, tzinfo=UTC)
    assert end == datetime(2026, 4, 9, 5, 0, tzinfo=UTC)


def test_daily_window_utc_household() -> None:
    now = datetime(2026, 4, 9, 15, 0, tzinfo=UTC)
    start, end = window_for_cadence("daily", now, UTC_TZ)
    assert start == datetime(2026, 4, 9, 0, 0, tzinfo=UTC)
    assert end == datetime(2026, 4, 10, 0, 0, tzinfo=UTC)


def test_daily_window_tokyo() -> None:
    # Tokyo = UTC+9, no DST.
    # 2026-04-09 15:00 UTC == 2026-04-10 00:00 Tokyo — exactly local midnight
    now = datetime(2026, 4, 9, 15, 0, tzinfo=UTC)
    start, end = window_for_cadence("daily", now, TOKYO)
    assert start == datetime(2026, 4, 9, 15, 0, tzinfo=UTC)  # 2026-04-10 00:00 JST
    assert end == datetime(2026, 4, 10, 15, 0, tzinfo=UTC)  # 2026-04-11 00:00 JST


def test_on_request_uses_daily_window() -> None:
    """Decision 3c: on_request chores have the same per-day floor as daily."""
    now = datetime(2026, 4, 9, 15, 0, tzinfo=UTC)
    daily = window_for_cadence("daily", now, CHICAGO)
    on_request = window_for_cadence("on_request", now, CHICAGO)
    assert daily == on_request


# ---------------------------------------------------------------------------
# DST transitions — daily
# ---------------------------------------------------------------------------


def test_daily_window_spans_dst_spring_forward_chicago() -> None:
    """On 2026-03-08 CST->CDT, clocks jump from 02:00 to 03:00 local.

    A daily window for that date should still run from local midnight of
    2026-03-08 to local midnight of 2026-03-09, which is 23 real hours.
    """
    # 2026-03-08 12:00 UTC == 06:00 CST or 07:00 CDT (depending on side)
    now = datetime(2026, 3, 8, 12, 0, tzinfo=UTC)
    start, end = window_for_cadence("daily", now, CHICAGO)
    # 2026-03-08 00:00 CST = 06:00 UTC
    assert start == datetime(2026, 3, 8, 6, 0, tzinfo=UTC)
    # 2026-03-09 00:00 CDT = 05:00 UTC
    assert end == datetime(2026, 3, 9, 5, 0, tzinfo=UTC)
    # 23-hour day
    assert (end - start).total_seconds() == 23 * 3600


def test_daily_window_spans_dst_fall_back_chicago() -> None:
    """On 2026-11-01 CDT->CST, clocks fall from 02:00 back to 01:00 local.

    A daily window for that date runs from local midnight to local midnight,
    which is 25 real hours.
    """
    now = datetime(2026, 11, 1, 12, 0, tzinfo=UTC)
    start, end = window_for_cadence("daily", now, CHICAGO)
    # 2026-11-01 00:00 CDT = 05:00 UTC
    assert start == datetime(2026, 11, 1, 5, 0, tzinfo=UTC)
    # 2026-11-02 00:00 CST = 06:00 UTC
    assert end == datetime(2026, 11, 2, 6, 0, tzinfo=UTC)
    assert (end - start).total_seconds() == 25 * 3600


# ---------------------------------------------------------------------------
# Weekly
# ---------------------------------------------------------------------------


def test_weekly_window_monday_start_chicago() -> None:
    # 2026-04-09 is a Thursday (weekday == 3). Monday of that week is 2026-04-06.
    now = datetime(2026, 4, 9, 15, 0, tzinfo=UTC)
    start, end = window_for_cadence("weekly", now, CHICAGO)
    # 2026-04-06 00:00 CDT = 05:00 UTC
    assert start == datetime(2026, 4, 6, 5, 0, tzinfo=UTC)
    # 2026-04-13 00:00 CDT = 05:00 UTC
    assert end == datetime(2026, 4, 13, 5, 0, tzinfo=UTC)
    assert start <= now < end


def test_weekly_window_on_a_monday() -> None:
    # 2026-04-06 is a Monday.
    now = datetime(2026, 4, 6, 18, 0, tzinfo=UTC)  # afternoon CDT
    start, end = window_for_cadence("weekly", now, CHICAGO)
    assert start == datetime(2026, 4, 6, 5, 0, tzinfo=UTC)
    assert end == datetime(2026, 4, 13, 5, 0, tzinfo=UTC)


def test_weekly_window_on_a_sunday_chicago() -> None:
    # 2026-04-12 is a Sunday; that week's Monday is 2026-04-06.
    now = datetime(2026, 4, 12, 20, 0, tzinfo=UTC)  # 15:00 CDT on Sunday
    start, end = window_for_cadence("weekly", now, CHICAGO)
    assert start == datetime(2026, 4, 6, 5, 0, tzinfo=UTC)
    assert end == datetime(2026, 4, 13, 5, 0, tzinfo=UTC)


def test_weekly_window_spans_dst_chicago() -> None:
    """Week containing DST spring-forward (2026-03-08, Sunday).

    Monday 2026-03-02 CST (UTC-6) -> Monday 2026-03-09 CDT (UTC-5)
    """
    now = datetime(2026, 3, 5, 12, 0, tzinfo=UTC)  # Thursday during that week
    start, end = window_for_cadence("weekly", now, CHICAGO)
    assert start == datetime(2026, 3, 2, 6, 0, tzinfo=UTC)  # 00:00 CST
    assert end == datetime(2026, 3, 9, 5, 0, tzinfo=UTC)  # 00:00 CDT
    # 7 days * 24 - 1 hour (spring forward)
    assert (end - start).total_seconds() == (7 * 24 - 1) * 3600


# ---------------------------------------------------------------------------
# Monthly
# ---------------------------------------------------------------------------


def test_monthly_window_mid_month_chicago() -> None:
    now = datetime(2026, 4, 15, 18, 0, tzinfo=UTC)
    start, end = window_for_cadence("monthly", now, CHICAGO)
    assert start == datetime(2026, 4, 1, 5, 0, tzinfo=UTC)  # 2026-04-01 00:00 CDT
    assert end == datetime(2026, 5, 1, 5, 0, tzinfo=UTC)  # 2026-05-01 00:00 CDT


def test_monthly_window_december_rolls_to_january() -> None:
    now = datetime(2026, 12, 20, 18, 0, tzinfo=UTC)
    start, end = window_for_cadence("monthly", now, CHICAGO)
    assert start == datetime(2026, 12, 1, 6, 0, tzinfo=UTC)  # CST, UTC-6
    assert end == datetime(2027, 1, 1, 6, 0, tzinfo=UTC)


def test_monthly_window_on_first_of_month() -> None:
    # 2026-04-01 07:00 UTC == 02:00 CDT, still April locally
    now = datetime(2026, 4, 1, 7, 0, tzinfo=UTC)
    start, end = window_for_cadence("monthly", now, CHICAGO)
    assert start == datetime(2026, 4, 1, 5, 0, tzinfo=UTC)
    assert end == datetime(2026, 5, 1, 5, 0, tzinfo=UTC)


def test_monthly_window_spans_dst_march() -> None:
    now = datetime(2026, 3, 15, 12, 0, tzinfo=UTC)
    start, end = window_for_cadence("monthly", now, CHICAGO)
    assert start == datetime(2026, 3, 1, 6, 0, tzinfo=UTC)  # 00:00 CST
    assert end == datetime(2026, 4, 1, 5, 0, tzinfo=UTC)  # 00:00 CDT


# ---------------------------------------------------------------------------
# Instant in window
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("cadence", ["daily", "weekly", "monthly", "on_request"])
def test_now_is_always_inside_returned_window(cadence: str) -> None:
    now = datetime(2026, 4, 9, 15, 0, tzinfo=UTC)
    start, end = window_for_cadence(cadence, now, CHICAGO)
    assert start <= now < end


def test_zoneinfo_resolves() -> None:
    # Sanity: ZoneInfo import works (zoneinfo bundles IANA data on Windows via tzdata).
    ZoneInfo("America/Chicago")
