#!/usr/bin/env python3
"""Talk to the Todoist API (v1) for the quickshell Todoist pill and card.

Used by ../Services/Todoist.qml. The API token lives in the GNOME keyring:

    secret-tool store --label=Todoist service todoist

Subcommands, each printing JSON:

    todoist.py list           tasks due today or overdue:
                              [{"id", "content", "priority", "project",
                                "projectColor", "labels", "due", "time",
                                "recurring", "overdue"}, ...]
    todoist.py meta           {"projects": [{"name", "color"}], "labels": [...]}
    todoist.py close ID       complete a task -> {"ok": true}
    todoist.py quick TEXT     quick add (Todoist parses dates, #project,
                              @label, p1..p4; no date means today)
                              -> {"ok": true, "content"}

Failures print {"error": "..."} (exit 0, so the caller always gets JSON);
"no-token" means the keyring has no token.
"""

import json
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import date, datetime, timezone

API = "https://api.todoist.com/api/v1"
FILTER = "today | overdue"

# Todoist's named project/label colors.
COLORS = {
    "berry_red": "#b8255f",
    "red": "#db4035",
    "orange": "#ff9933",
    "yellow": "#fad000",
    "olive_green": "#afb83b",
    "lime_green": "#7ecc49",
    "green": "#299438",
    "mint_green": "#6accbc",
    "teal": "#158fad",
    "sky_blue": "#14aaf5",
    "light_blue": "#96c3eb",
    "blue": "#4073ff",
    "grape": "#884dff",
    "violet": "#af38eb",
    "lavender": "#eb96eb",
    "magenta": "#e05194",
    "salmon": "#ff8d85",
    "charcoal": "#808080",
    "grey": "#b8b8b8",
    "taupe": "#ccac93",
}


class Error(Exception):
    pass


def token():
    try:
        out = subprocess.run(
            ["secret-tool", "lookup", "service", "todoist"],
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired):
        raise Error("no-token")
    tok = out.stdout.strip()
    if not tok:
        raise Error("no-token")
    return tok


def request(tok, method, path, params=None, body=None):
    url = API + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", "Bearer " + tok)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            raw = resp.read()
    except urllib.error.HTTPError as e:
        raise Error(f"HTTP {e.code}: {e.read().decode(errors='replace')[:200]}")
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        raise Error(f"network: {getattr(e, 'reason', e)}")
    return json.loads(raw) if raw else None


def paged(tok, path, params=None):
    """All results of a cursor-paginated list endpoint."""
    params = dict(params or {}, limit=200)
    results = []
    while True:
        page = request(tok, "GET", path, params) or {}
        results += page.get("results", [])
        cursor = page.get("next_cursor")
        if not cursor:
            return results
        params["cursor"] = cursor


def projects(tok):
    return paged(tok, "/projects")


def overdue(when):
    """A date before today, or a time that has passed."""
    if not when:
        return False
    if "T" not in when:
        return when < date.today().isoformat()
    try:
        dt = datetime.fromisoformat(when)
    except ValueError:
        return False
    now = datetime.now(timezone.utc) if dt.tzinfo else datetime.now()
    return dt < now


def cmd_list(tok):
    tasks = paged(tok, "/tasks/filter", {"query": FILTER})
    by_id = {p["id"]: p for p in projects(tok)}
    out = []
    for t in tasks:
        due = t.get("due") or {}
        # "2026-10-03", or a datetime: floating "2026-10-03T14:00:00", or
        # UTC "…Z" when it has a fixed timezone.
        when = due.get("datetime") or due.get("date") or ""
        project = by_id.get(t.get("project_id"), {})
        out.append(
            {
                "id": t["id"],
                "content": t.get("content", ""),
                # The API's 4 is the UI's p1.
                "priority": 5 - t.get("priority", 1),
                "project": "Inbox"
                if project.get("inbox_project") or project.get("is_inbox_project")
                else project.get("name", ""),
                "projectColor": COLORS.get(project.get("color"), "#808080"),
                "labels": t.get("labels", []),
                "due": when,
                "time": "T" in when,
                "recurring": bool(due.get("is_recurring")),
                "overdue": overdue(when),
            }
        )
    return out


def cmd_meta(tok):
    labels = paged(tok, "/labels")
    return {
        "projects": [
            {"name": p["name"], "color": COLORS.get(p.get("color"), "#808080")}
            for p in projects(tok)
            if not p.get("is_archived") and not p.get("is_deleted")
        ],
        "labels": [
            {"name": l["name"], "color": COLORS.get(l.get("color"), "#808080")}
            for l in labels
        ],
    }


def cmd_close(tok, task_id):
    request(tok, "POST", f"/tasks/{urllib.parse.quote(task_id)}/close")
    return {"ok": True}


def cmd_quick(tok, text):
    task = request(tok, "POST", "/tasks/quick", body={"text": text}) or {}
    # The card lists today | overdue, so an undated task would vanish from
    # it; default to today like Todoist's own Today view does.
    if not task.get("due") and task.get("id"):
        task = request(
            tok,
            "POST",
            f"/tasks/{urllib.parse.quote(task['id'])}",
            body={"due_string": "today"},
        ) or task
    return {"ok": True, "content": task.get("content", text)}


def main(argv):
    if not argv or argv[0] not in ("list", "meta", "close", "quick"):
        print(__doc__, file=sys.stderr)
        return 2
    try:
        tok = token()
        cmd, args = argv[0], argv[1:]
        if cmd == "list":
            result = cmd_list(tok)
        elif cmd == "meta":
            result = cmd_meta(tok)
        elif cmd == "close":
            result = cmd_close(tok, args[0])
        else:
            result = cmd_quick(tok, " ".join(args))
    except Error as e:
        result = {"error": str(e)}
    except (IndexError, KeyError, ValueError) as e:
        result = {"error": f"unexpected: {e!r}"}
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
