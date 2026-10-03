#!/usr/bin/env python3
"""Print Thunderbird calendar events in a date range as JSON.

Used by the quickshell calendar card (../CalendarCard.qml). Reads the
calendar cache Thunderbird keeps in its profile
(calendar-data/{cache,local}.sqlite), so events are as fresh as
Thunderbird's last sync. Thunderbird itself doesn't need to be running.

    thunderbird-events.py --from 2026-10-01 --to 2026-10-31

prints [{"title", "start", "end", "allDay", "calendar", "color"}, ...],
sorted by start. Timed events use local ISO datetimes with offset; all-day
events use dates, with "end" exclusive. The range is in local dates,
inclusive.

The profile is the one whose calendar data changed most recently;
THUNDERBIRD_PROFILE (a profile directory) overrides that.
"""

import argparse
import json
import os
import re
import shutil
import sqlite3
import sys
import tempfile
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from dateutil.rrule import rrulestr

# Item flags, from Thunderbird's calStorageCalendar.
FLAG_ALLDAY = 8
FLAG_RECURRING = 16



def local_zone():
    """The system zone with its DST rules -- datetime.now().astimezone()
    only gives today's fixed offset, which is wrong across a DST change."""
    name = os.environ.get("TZ", "").lstrip(":")
    if not name:
        target = os.path.realpath("/etc/localtime")
        name = target.split("zoneinfo/", 1)[1] if "zoneinfo/" in target else ""
    try:
        return ZoneInfo(name) if name else ZoneInfo("localtime")
    except (ZoneInfoNotFoundError, ValueError):
        return datetime.now().astimezone().tzinfo


LOCAL_TZ = local_zone()


def find_profile() -> Path | None:
    override = os.environ.get("THUNDERBIRD_PROFILE")
    if override:
        return Path(override).expanduser()
    root = Path.home() / ".thunderbird"

    def last_change(profile: Path) -> float:
        data = profile / "calendar-data"
        times = [f.stat().st_mtime for f in data.glob("*.sqlite*")]
        return max(times, default=0)

    profiles = [p for p in root.iterdir() if (p / "calendar-data" / "cache.sqlite").exists()] if root.is_dir() else []
    return max(profiles, key=last_change, default=None)


def read_calendars(profile: Path) -> dict:
    """Calendar id -> {name, color} for the calendars shown in Thunderbird."""
    prefs = (profile / "prefs.js").read_text(errors="replace")
    pattern = re.compile(r'user_pref\("calendar\.registry\.([^.]+)\.([^"]+)",\s*(.+?)\);')
    registry: dict = {}
    for cal_id, key, raw in pattern.findall(prefs):
        try:
            value = json.loads(raw)
        except json.JSONDecodeError:
            continue
        registry.setdefault(cal_id, {})[key] = value
    return {
        cal_id: {"name": c.get("name", ""), "color": c.get("color", "#888888")}
        for cal_id, c in registry.items()
        if not c.get("disabled", False) and c.get("calendar-main-in-composite", True)
    }


def connect(db: Path, tmp: Path) -> sqlite3.Connection:
    """Open read-only; if Thunderbird holds a lock, read a copy instead."""
    try:
        conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
        conn.execute("select 1 from cal_events limit 1")
        return conn
    except sqlite3.OperationalError:
        for suffix in ("", "-wal", "-shm"):
            src = Path(str(db) + suffix)
            if src.exists():
                shutil.copy(src, tmp / (db.name + suffix))
        return sqlite3.connect(tmp / db.name)


def zone(name: str | None):
    if not name or name == "floating":
        return LOCAL_TZ
    if name == "UTC":
        return timezone.utc
    try:
        return ZoneInfo(name)
    except (ZoneInfoNotFoundError, ValueError):
        return LOCAL_TZ


def from_us(us: int, tz) -> datetime:
    return datetime.fromtimestamp(us / 1_000_000, timezone.utc).astimezone(tz)


def parse_ical_dates(line: str, tz) -> list[datetime]:
    """EXDATE/RDATE values ("EXDATE;TZID=…:20240101T170000,…") as aware datetimes."""
    params, _, values = line.partition(":")
    tzid = re.search(r"TZID=([^;:]+)", params)
    value_tz = zone(tzid.group(1)) if tzid else tz
    out = []
    for v in values.split(","):
        v = v.strip()
        if not v:
            continue
        if v.endswith("Z"):
            out.append(datetime.strptime(v, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc))
        elif "T" in v:
            out.append(datetime.strptime(v, "%Y%m%dT%H%M%S").replace(tzinfo=value_tz))
        else:
            out.append(datetime.combine(datetime.strptime(v, "%Y%m%d").date(), time(), value_tz))
    return out


def utc_until(rule: str, tz) -> str:
    """dateutil wants UNTIL in UTC when DTSTART is aware; Thunderbird also
    stores floating and date-only ones."""

    def fix(m: re.Match) -> str:
        stamp, utc = m.group(1), m.group(2)
        if utc:
            return m.group(0)
        if "T" in stamp:
            until = datetime.strptime(stamp, "%Y%m%dT%H%M%S").replace(tzinfo=tz)
        else:
            until = datetime.combine(datetime.strptime(stamp, "%Y%m%d").date(), time(23, 59, 59), tz)
        return "UNTIL=" + until.astimezone(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    return re.sub(r"UNTIL=(\d{8}(?:T\d{6})?)(Z?)", fix, rule)


def occurrences(start: datetime, lines: list[str], after: datetime, before: datetime) -> list[datetime]:
    """Instance starts of a recurring event between after and before."""
    tz = start.tzinfo
    found: set[datetime] = set()
    excluded: set[datetime] = set()
    for line in lines:
        line = line.strip()
        if line.startswith("RRULE"):
            rule = rrulestr(utc_until(line, tz), dtstart=start)
            found.update(rule.between(after, before, inc=True))
        elif line.startswith("RDATE"):
            found.update(d for d in parse_ical_dates(line, tz) if after <= d <= before)
        elif line.startswith("EXDATE"):
            excluded.update(parse_ical_dates(line, tz))
    excluded_utc = {d.astimezone(timezone.utc) for d in excluded}
    return sorted(d for d in found if d.astimezone(timezone.utc) not in excluded_utc)


def events_in(conn: sqlite3.Connection, calendars: dict, first: datetime, last: datetime) -> list[dict]:
    rows = conn.execute(
        "select cal_id, id, title, flags, event_start, event_end, event_start_tz, recurrence_id, ical_status from cal_events"
    ).fetchall()
    recurrence: dict = {}
    for cal_id, item_id, line in conn.execute("select cal_id, item_id, icalString from cal_recurrence"):
        recurrence.setdefault((cal_id, item_id), []).append(line)

    # Overridden instances of recurring events, keyed by the instance start
    # they replace (µs). They also show up as events of their own below.
    overridden: dict = {}
    for row in rows:
        cal_id, item_id, rec_id = row[0], row[1], row[7]
        if rec_id is not None:
            overridden.setdefault((cal_id, item_id), set()).add(rec_id)

    out = []

    def add(cal_id, title, starts: datetime, ends: datetime, all_day: bool):
        if not (starts < last and ends > first):
            return
        cal = calendars[cal_id]
        if all_day:
            start_s, end_s = starts.date().isoformat(), ends.date().isoformat()
        else:
            start_s = starts.astimezone(LOCAL_TZ).isoformat(timespec="minutes")
            end_s = ends.astimezone(LOCAL_TZ).isoformat(timespec="minutes")
        out.append({"title": title or "(no title)", "start": start_s, "end": end_s, "allDay": all_day,
                    "calendar": cal["name"], "color": cal["color"], "_sort": starts.astimezone(timezone.utc)})

    for cal_id, item_id, title, flags, start_us, end_us, tz_name, rec_id, status in rows:
        if cal_id not in calendars or status == "CANCELLED" or start_us is None:
            continue
        tz = zone(tz_name)
        start = from_us(start_us, tz)
        end = from_us(end_us, tz) if end_us is not None else start
        all_day = bool(flags & FLAG_ALLDAY)
        if rec_id is not None or not flags & FLAG_RECURRING:
            add(cal_id, title, start, end, all_day)
            continue
        duration = end - start
        skip = overridden.get((cal_id, item_id), set())
        for s in occurrences(start, recurrence.get((cal_id, item_id), []), first - duration, last):
            if int(s.timestamp() * 1_000_000) in skip:
                continue
            add(cal_id, title, s, s + duration, all_day)
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description="Print Thunderbird calendar events in a date range as JSON.")
    parser.add_argument("--from", dest="first", type=date.fromisoformat, default=date.today())
    parser.add_argument("--to", dest="last", type=date.fromisoformat, default=date.today() + timedelta(days=14))
    args = parser.parse_args()

    profile = find_profile()
    if profile is None:
        print("[]")
        return 0
    calendars = read_calendars(profile)
    first = datetime.combine(args.first, time(), LOCAL_TZ)
    last = datetime.combine(args.last + timedelta(days=1), time(), LOCAL_TZ)

    events = []
    with tempfile.TemporaryDirectory() as tmp:
        for name in ("cache.sqlite", "local.sqlite"):
            db = profile / "calendar-data" / name
            if not db.exists():
                continue
            conn = connect(db, Path(tmp))
            try:
                events += events_in(conn, calendars, first, last)
            finally:
                conn.close()

    events.sort(key=lambda e: (e["_sort"], not e["allDay"], e["title"]))
    for e in events:
        del e["_sort"]
    json.dump(events, sys.stdout, ensure_ascii=False)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
