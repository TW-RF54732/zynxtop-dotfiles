#!/usr/bin/env python3
"""Calendar backend for the Quickshell sidebar.

Long-running JSON-lines service: one request object per stdin line, one reply per
stdout line. Storage is a set of vdirs (one directory of .ics files per calendar)
under $XDG_DATA_HOME/calendars:

- ``local/``      events created from the shell (read/write)
- ``sub-<id>/``   ICS subscriptions, synced read-only by vdirsyncer
- anything else   other vdirs (e.g. from khal); shown read-only

Parsing, recurrence expansion and time zones are handled by icalendar,
recurring-ical-events and x-wr-timezone; subscriptions by vdirsyncer.
"""
import argparse
import datetime as dt
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import uuid

MISSING = []
try:
    import icalendar
except ImportError:
    MISSING.append("python-icalendar")
try:
    import recurring_ical_events
except ImportError:
    MISSING.append("python-recurring-ical-events")
try:
    import x_wr_timezone  # noqa: F401  (used by recurring_ical_events.of)
except ImportError:
    MISSING.append("python-x-wr-timezone")
if not shutil.which("vdirsyncer"):
    MISSING.append("vdirsyncer")

from zoneinfo import ZoneInfo

LOCAL_ID = "local"
LOCAL_NAME = "本機"
REPEATS = {"DAILY", "WEEKLY", "MONTHLY", "YEARLY"}
PRODID = "-//quickshell//sidebar calendar//EN"

_out_lock = threading.Lock()


def emit(message):
    with _out_lock:
        sys.stdout.write(json.dumps(message, ensure_ascii=False) + "\n")
        sys.stdout.flush()


def atomic_write(path, data, mode=0o644):
    directory = os.path.dirname(path)
    os.makedirs(directory, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix=".tmp-", dir=directory)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
        os.chmod(temp, mode)
        os.replace(temp, path)
    except BaseException:
        if os.path.exists(temp):
            os.unlink(temp)
        raise


def parse_day(text):
    return dt.date.fromisoformat(str(text))


class Backend:
    def __init__(self, data_dir, state_dir, tz_name):
        self.data_dir = data_dir
        self.state_dir = state_dir
        self.tz = ZoneInfo(tz_name)
        self.cache = {}  # path -> (mtime_ns, size, Calendar)
        self.subs_path = os.path.join(state_dir, "subscriptions.json")
        self.config_path = os.path.join(state_dir, "vdirsyncer.conf")
        self.sync_lock = threading.Lock()
        self.syncing = False
        self.sync_pending = False
        os.makedirs(os.path.join(data_dir, LOCAL_ID), exist_ok=True)
        os.makedirs(state_dir, mode=0o700, exist_ok=True)
        name_file = os.path.join(data_dir, LOCAL_ID, "displayname")
        if not os.path.exists(name_file):
            atomic_write(name_file, LOCAL_NAME.encode())

    # ---- calendars -------------------------------------------------------
    def calendars(self):
        result = []
        if not os.path.isdir(self.data_dir):
            return result
        for entry in sorted(os.listdir(self.data_dir)):
            path = os.path.join(self.data_dir, entry)
            if entry.startswith(".") or not os.path.isdir(path):
                continue
            name = entry
            try:
                with open(os.path.join(path, "displayname"), encoding="utf-8") as stream:
                    name = stream.read().strip() or entry
            except OSError:
                pass
            result.append({"id": entry, "name": name, "readOnly": entry != LOCAL_ID, "path": path})
        return result

    def load(self, path):
        stat = os.stat(path)
        cached = self.cache.get(path)
        if cached and cached[0] == stat.st_mtime_ns and cached[1] == stat.st_size:
            return cached[2]
        with open(path, "rb") as stream:
            calendar = icalendar.Calendar.from_ical(stream.read())
        self.cache[path] = (stat.st_mtime_ns, stat.st_size, calendar)
        return calendar

    def files(self, calendar):
        try:
            names = sorted(os.listdir(calendar["path"]))
        except OSError:
            return []
        return [n for n in names if n.endswith(".ics") and not n.startswith(".")]

    # ---- queries ---------------------------------------------------------
    def to_local(self, value):
        """Date stays a date; datetimes become naive Taipei wall time."""
        if isinstance(value, dt.datetime):
            if value.tzinfo is None:
                return value
            return value.astimezone(self.tz).replace(tzinfo=None)
        return value

    def occurrence_bounds(self, component):
        start = component.get("DTSTART")
        if start is None:
            return None
        start = self.to_local(start.dt)
        end_prop = component.get("DTEND")
        if end_prop is not None:
            end = self.to_local(end_prop.dt)
        elif component.get("DURATION") is not None:
            end = start + component.get("DURATION").dt
        elif isinstance(start, dt.datetime):
            end = start
        else:
            end = start + dt.timedelta(days=1)
        all_day = not isinstance(start, dt.datetime)
        if all_day and isinstance(end, dt.datetime):
            end = end.date()
        if not all_day and not isinstance(end, dt.datetime):
            end = dt.datetime.combine(end, dt.time())
        if end < start:
            end = start
        return start, end, all_day

    def range(self, start_day, end_day, only=None):
        start_dt = dt.datetime.combine(start_day, dt.time(), self.tz)
        end_dt = dt.datetime.combine(end_day, dt.time(), self.tz)
        events = []
        errors = []
        for calendar in self.calendars():
            if only and calendar["id"] not in only:
                continue
            for name in self.files(calendar):
                path = os.path.join(calendar["path"], name)
                try:
                    ical = self.load(path)
                    # The library stamps RECURRENCE-ID on every occurrence, so a series is
                    # recognized by its master's RRULE/RDATE instead.
                    series = {str(c.get("UID", "")) for c in ical.walk("VEVENT")
                              if c.get("RRULE") is not None or c.get("RDATE") is not None}
                    query = recurring_ical_events.of(ical, skip_bad_series=True)
                    for component in query.between(start_dt, end_dt):
                        recurring = str(component.get("UID", "")) in series
                        events.extend(self.pieces(calendar, name, component, start_day, end_day, recurring))
                except Exception as error:  # one broken file must not hide the rest
                    errors.append(f"{calendar['id']}/{name}: {error}")
        return events, errors

    def pieces(self, calendar, filename, component, start_day, end_day, recurring):
        bounds = self.occurrence_bounds(component)
        if bounds is None:
            return []
        start, end, all_day = bounds
        recurrence = component.get("RECURRENCE-ID")
        ident = recurrence.dt.isoformat() if recurrence is not None else start.isoformat()
        base = {
            "key": f"{calendar['id']}/{filename}/{ident}",
            "uid": str(component.get("UID", "")),
            "calendar": calendar["id"],
            "calendarName": calendar["name"],
            "readOnly": calendar["readOnly"],
            "title": str(component.get("SUMMARY", "")) or "（無標題）",
            "location": str(component.get("LOCATION", "")),
            "description": str(component.get("DESCRIPTION", "")),
            "allDay": all_day,
            "recurring": recurring,
        }
        if all_day:
            first, last = start, max(start + dt.timedelta(days=1), end)
            base["startLabel"] = first.isoformat()
            base["endLabel"] = (last - dt.timedelta(days=1)).isoformat()
        else:
            first = start.date()
            last = end.date() + dt.timedelta(days=1)
            if end > start and end.time() == dt.time():
                last = end.date()  # ends exactly at midnight
            base["startLabel"] = start.strftime("%Y-%m-%d %H:%M")
            base["endLabel"] = end.strftime("%Y-%m-%d %H:%M")
        base["multiDay"] = (last - first).days > 1
        result = []
        day = max(first, start_day)
        while day < last and day < end_day:
            piece = dict(base, date=day.isoformat())
            if all_day:
                piece["startMin"], piece["endMin"] = 0, 1440
            else:
                day_start = dt.datetime.combine(day, dt.time())
                piece["startMin"] = max(0, int((start - day_start).total_seconds() // 60))
                piece["endMin"] = min(1440, int((end - day_start).total_seconds() // 60))
            result.append(piece)
            day += dt.timedelta(days=1)
        return result

    # ---- local CRUD ------------------------------------------------------
    def local_path(self, uid):
        safe = re.sub(r"[^A-Za-z0-9@._-]", "_", uid)
        return os.path.join(self.data_dir, LOCAL_ID, safe + ".ics")

    def find_local(self, uid):
        calendar = next(c for c in self.calendars() if c["id"] == LOCAL_ID)
        for name in self.files(calendar):
            path = os.path.join(calendar["path"], name)
            try:
                for component in self.load(path).walk("VEVENT"):
                    if str(component.get("UID", "")) == uid:
                        return path
            except Exception:
                continue
        return None

    def build_event(self, uid, fields, previous=None):
        title = str(fields.get("title", "")).strip()
        if not title:
            raise ValueError("標題不可空白")
        day = parse_day(fields.get("date"))
        event = icalendar.Event()
        event.add("UID", uid)
        event.add("DTSTAMP", dt.datetime.now(dt.timezone.utc))
        if previous is not None and previous.get("CREATED") is not None:
            event.add("CREATED", previous.get("CREATED").dt)
        else:
            event.add("CREATED", dt.datetime.now(dt.timezone.utc))
        event.add("LAST-MODIFIED", dt.datetime.now(dt.timezone.utc))
        event.add("SUMMARY", title)
        if fields.get("allDay"):
            days = max(1, int(fields.get("days", 1)))
            event.add("DTSTART", day)
            event.add("DTEND", day + dt.timedelta(days=days))
        else:
            start_min = int(fields.get("startMin", 0))
            end_min = int(fields.get("endMin", start_min + 60))
            if not 0 <= start_min < 1440 or not 0 < end_min <= 1440:
                raise ValueError("時間超出範圍")
            if end_min <= start_min:
                raise ValueError("結束時間需晚於開始時間")
            midnight = dt.datetime.combine(day, dt.time(), self.tz)
            event.add("DTSTART", midnight + dt.timedelta(minutes=start_min))
            event.add("DTEND", midnight + dt.timedelta(minutes=end_min))
        for prop, key in (("LOCATION", "location"), ("DESCRIPTION", "description")):
            value = str(fields.get(key, "")).strip()
            if value:
                event.add(prop, value)
        repeat = str(fields.get("repeat", "")).upper()
        if repeat in REPEATS:
            event.add("RRULE", {"FREQ": repeat})
        elif repeat:
            raise ValueError("不支援的重複規則")
        calendar = icalendar.Calendar()
        calendar.add("PRODID", PRODID)
        calendar.add("VERSION", "2.0")
        calendar.add_component(event)
        if hasattr(calendar, "add_missing_timezones"):
            calendar.add_missing_timezones()
        return calendar

    def create(self, fields):
        uid = str(uuid.uuid4()) + "@quickshell"
        atomic_write(self.local_path(uid), self.build_event(uid, fields).to_ical())
        return uid

    def update(self, uid, fields):
        path = self.find_local(uid)
        if path is None:
            raise ValueError("找不到事項")
        previous = next(iter(self.load(path).walk("VEVENT")), None)
        # Editing applies to the whole series: the file is rewritten with one master.
        atomic_write(path, self.build_event(uid, fields, previous).to_ical())

    def delete(self, uid):
        path = self.find_local(uid)
        if path is None:
            raise ValueError("找不到事項")
        os.unlink(path)
        self.cache.pop(path, None)

    def get(self, uid):
        path = self.find_local(uid)
        if path is None:
            raise ValueError("找不到事項")
        master = None
        for component in self.load(path).walk("VEVENT"):
            if component.get("RECURRENCE-ID") is None:
                master = component
                break
        if master is None:
            raise ValueError("找不到事項")
        start, end, all_day = self.occurrence_bounds(master)
        rule = master.get("RRULE")
        freq = rule.get("FREQ", [""])[0] if rule is not None else ""
        result = {
            "uid": uid,
            "title": str(master.get("SUMMARY", "")),
            "location": str(master.get("LOCATION", "")),
            "description": str(master.get("DESCRIPTION", "")),
            "allDay": all_day,
            "repeat": freq if freq in REPEATS else "",
        }
        if all_day:
            result.update(date=start.isoformat(), days=max(1, (end - start).days), startMin=540, endMin=600)
        else:
            day_start = dt.datetime.combine(start.date(), dt.time())
            result.update(date=start.date().isoformat(), days=1,
                          startMin=int((start - day_start).total_seconds() // 60),
                          endMin=min(1440, int((end - day_start).total_seconds() // 60)))
        return result

    # ---- subscriptions ---------------------------------------------------
    def read_subscriptions(self):
        try:
            with open(self.subs_path, encoding="utf-8") as stream:
                items = json.load(stream).get("items", [])
            return [item for item in items if isinstance(item, dict) and item.get("id")]
        except (OSError, ValueError):
            return []

    def write_subscriptions(self, items):
        atomic_write(self.subs_path, json.dumps({"items": items}, ensure_ascii=False, indent=2).encode(), 0o600)
        self.write_config(items)

    def write_config(self, items):
        status = os.path.join(self.state_dir, "vdirsyncer-status") + "/"
        lines = ["[general]", f"status_path = {json.dumps(status)}", ""]
        for item in items:
            pair = item["id"].replace("-", "_")
            lines += [
                f"[pair {pair}]",
                f'a = "{pair}_remote"',
                f'b = "{pair}_local"',
                "collections = null",
                'conflict_resolution = "a wins"',
                "",
                f"[storage {pair}_remote]",
                'type = "http"',
                f"url = {json.dumps(item['url'])}",
                "",
                f"[storage {pair}_local]",
                'type = "filesystem"',
                f"path = {json.dumps(os.path.join(self.data_dir, item['id']) + '/')}",
                'fileext = ".ics"',
                "",
            ]
        atomic_write(self.config_path, "\n".join(lines).encode(), 0o600)

    @staticmethod
    def normalize_url(url):
        url = str(url or "").strip()
        if url.lower().startswith("webcal://"):
            url = "https://" + url[len("webcal://"):]
        if not re.match(r"^https?://[^\s]+$", url, re.IGNORECASE):
            raise ValueError("網址需為 http(s):// 或 webcal://")
        return url

    def subscribe(self, name, url):
        name = str(name or "").strip()
        if not name:
            raise ValueError("名稱不可空白")
        url = self.normalize_url(url)
        items = self.read_subscriptions()
        if any(item["url"] == url for item in items):
            raise ValueError("已訂閱此網址")
        ident = "sub-" + uuid.uuid4().hex[:8]
        directory = os.path.join(self.data_dir, ident)
        os.makedirs(directory, exist_ok=True)
        atomic_write(os.path.join(directory, "displayname"), name.encode())
        items.append({"id": ident, "name": name, "url": url, "lastSync": "", "error": ""})
        self.write_subscriptions(items)
        return ident

    def unsubscribe(self, ident):
        items = self.read_subscriptions()
        if not any(item["id"] == ident for item in items):
            raise ValueError("找不到訂閱")
        self.write_subscriptions([item for item in items if item["id"] != ident])
        if re.fullmatch(r"sub-[0-9a-f]{8}", ident):
            shutil.rmtree(os.path.join(self.data_dir, ident), ignore_errors=True)
            pair = ident.replace("-", "_")
            status = os.path.join(self.state_dir, "vdirsyncer-status")
            if os.path.isdir(status):
                for entry in os.listdir(status):
                    if entry.startswith(pair):
                        target = os.path.join(status, entry)
                        if os.path.isdir(target):
                            shutil.rmtree(target, ignore_errors=True)
                        else:
                            os.unlink(target)
        for path in [p for p in self.cache if os.sep + ident + os.sep in p]:
            self.cache.pop(path, None)

    def public_subscriptions(self):
        return self.read_subscriptions()

    @staticmethod
    def vdirsyncer_error(output, step):
        lines = [l.strip() for l in output.splitlines() if l.strip()]
        useful = [l for l in lines if l.lower().startswith(("error:", "critical:", "warning:"))
                  and "-vdebug" not in l and "unknown error" not in l.lower()]
        picked = useful or [l for l in lines if "-vdebug" not in l]
        text = " ".join(picked[-2:]) if picked else f"vdirsyncer {step} failed"
        return re.sub(r"^(error|critical|warning):\s*", "", text, flags=re.IGNORECASE)

    def sync(self):
        """Runs vdirsyncer per pair so one failing feed does not block the others."""
        if not self.sync_lock.acquire(blocking=False):
            self.sync_pending = True  # run once more when the current pass ends
            return False
        self.syncing = True

        def worker():
            emit({"op": "syncing", "value": True})
            try:
                while True:
                    self.sync_pending = False
                    self.sync_pass()
                    if not self.sync_pending:
                        break
            except Exception as error:
                emit({"op": "error", "request": "sync", "message": str(error)})
            finally:
                self.syncing = False
                self.sync_lock.release()
                emit({"op": "syncing", "value": False})
                emit({"op": "changed"})
                if self.sync_pending:  # requested between the last pass and the release
                    self.sync()

        threading.Thread(target=worker, daemon=True).start()
        return True

    def sync_pass(self):
        items = self.read_subscriptions()
        self.write_config(items)
        env = dict(os.environ, VDIRSYNCER_CONFIG=self.config_path)
        now = dt.datetime.now(self.tz).strftime("%Y-%m-%d %H:%M")
        for item in items:
            pair = item["id"].replace("-", "_")
            os.makedirs(os.path.join(self.data_dir, item["id"]), exist_ok=True)
            error = ""
            for args in (["discover", "--no-list", pair], ["sync", pair]):
                try:
                    done = subprocess.run(["vdirsyncer", *args], env=env, stdin=subprocess.DEVNULL,
                                          capture_output=True, text=True, timeout=120)
                except subprocess.TimeoutExpired:
                    error = "逾時"
                    break
                if done.returncode != 0:
                    error = self.vdirsyncer_error(done.stderr + "\n" + done.stdout, args[0])
                    break
            item["error"] = error[:300]
            if not error:
                item["lastSync"] = now
        # Merge results into the current list: entries added or removed meanwhile are kept as-is.
        results = {item["id"]: item for item in items}
        merged = []
        for item in self.read_subscriptions():
            done = results.get(item["id"])
            if done is not None and done["url"] == item["url"]:
                item = dict(item, lastSync=done["lastSync"], error=done["error"])
            merged.append(item)
        self.write_subscriptions(merged)
        emit({"op": "subscriptions", "items": self.public_subscriptions()})

    # ---- dispatch --------------------------------------------------------
    def handle(self, request):
        op = request.get("op")
        reply = {"op": op}
        if "id" in request:
            reply["id"] = request["id"]
        if op == "range":
            only = request.get("calendars")
            events, errors = self.range(parse_day(request["start"]), parse_day(request["end"]), only)
            reply.update(start=request["start"], end=request["end"], events=events, errors=errors[:20])
            if "tag" in request:
                reply["tag"] = request["tag"]
            return [reply]
        if op == "calendars":
            reply["items"] = [{k: c[k] for k in ("id", "name", "readOnly")} for c in self.calendars()]
            return [reply]
        if op == "get":
            reply["event"] = self.get(str(request["uid"]))
            return [reply]
        if op == "create":
            reply["uid"] = self.create(request.get("event", {}))
            return [reply, {"op": "changed"}]
        if op == "update":
            self.update(str(request["uid"]), request.get("event", {}))
            reply["uid"] = request["uid"]
            return [reply, {"op": "changed"}]
        if op == "delete":
            self.delete(str(request["uid"]))
            reply["uid"] = request["uid"]
            return [reply, {"op": "changed"}]
        if op == "subscriptions":
            reply["items"] = self.public_subscriptions()
            return [reply]
        if op == "subscribe":
            reply["subscriptionId"] = self.subscribe(request.get("name"), request.get("url"))
            self.sync()
            return [reply, {"op": "subscriptions", "items": self.public_subscriptions()}]
        if op == "unsubscribe":
            self.unsubscribe(str(request.get("subscriptionId", "")))
            return [reply, {"op": "subscriptions", "items": self.public_subscriptions()}, {"op": "changed"}]
        if op == "sync":
            reply["started"] = self.sync()
            return [reply]
        raise ValueError(f"unknown op: {op}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--state", required=True, help="directory for subscriptions and vdirsyncer state")
    parser.add_argument("--data", default=os.path.join(
        os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"), "calendars"))
    parser.add_argument("--tz", default="Asia/Taipei")
    args = parser.parse_args()

    if MISSING:
        emit({"op": "unavailable", "missing": MISSING})
        for _ in sys.stdin:  # stay alive so the host does not respawn us in a loop
            pass
        return 0

    backend = Backend(args.data, args.state, args.tz)
    emit({"op": "ready", "timeZone": args.tz})
    emit({"op": "subscriptions", "items": backend.public_subscriptions()})
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        request = {}
        try:
            request = json.loads(line)
            for message in backend.handle(request):
                emit(message)
        except Exception as error:
            reply = {"op": "error", "request": request.get("op", ""), "message": str(error)}
            if "id" in request:
                reply["id"] = request["id"]
            emit(reply)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
