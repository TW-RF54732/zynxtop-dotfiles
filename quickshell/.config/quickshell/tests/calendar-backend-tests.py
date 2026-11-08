"""Protocol tests for services/calendar_backend.py, run by tests/run-calendar.sh.

Drives the real backend over its JSON-lines protocol in a temporary data/state
directory; the subscription case serves an ICS file from a local HTTP server.
"""
import functools
import http.server
import json
import os
import queue
import subprocess
import sys
import tempfile
import threading
import time
import unittest

BACKEND = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "services", "calendar_backend.py")

FEED = """BEGIN:VCALENDAR
VERSION:2.0
PRODID:test
X-WR-TIMEZONE:Asia/Taipei
BEGIN:VEVENT
UID:weekly@test
DTSTAMP:20261101T000000Z
DTSTART:20261102T020000Z
DTEND:20261102T033000Z
RRULE:FREQ=WEEKLY;COUNT=4
EXDATE:20261109T020000Z
SUMMARY:週會
END:VEVENT
BEGIN:VEVENT
UID:holiday@test
DTSTAMP:20261101T000000Z
DTSTART;VALUE=DATE:20261110
DTEND;VALUE=DATE:20261112
SUMMARY:連假
END:VEVENT
BEGIN:VEVENT
UID:overnight@test
DTSTAMP:20261101T000000Z
DTSTART;TZID=Asia/Taipei:20261108T230000
DTEND;TZID=Asia/Taipei:20261109T013000
SUMMARY:夜車
END:VEVENT
END:VCALENDAR
"""


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


class Backend:
    def __init__(self, root):
        self.process = subprocess.Popen(
            [sys.executable, "-I", BACKEND, "--state", os.path.join(root, "state"),
             "--data", os.path.join(root, "data")],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
        self.messages = queue.Queue()
        threading.Thread(target=self.read, daemon=True).start()
        self.wait("ready")

    def read(self):
        for line in self.process.stdout:
            self.messages.put(json.loads(line))

    def send(self, message):
        self.process.stdin.write(json.dumps(message) + "\n")
        self.process.stdin.flush()

    def wait(self, op, timeout=30, check=None):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try:
                message = self.messages.get(timeout=max(0.05, deadline - time.monotonic()))
            except queue.Empty:
                break
            if message.get("op") == op and (check is None or check(message)):
                return message
        raise AssertionError(f"timed out waiting for {op}")

    def call(self, message, reply=None):
        self.send(message)
        return self.wait(reply or message["op"])

    def range(self, start, end, **extra):
        return self.call(dict(op="range", start=start, end=end, **extra))["events"]

    def close(self):
        self.process.stdin.close()
        self.process.wait(timeout=10)
        self.process.stdout.close()


class BackendTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.backend = Backend(self.temp.name)

    def tearDown(self):
        self.backend.close()
        self.temp.cleanup()

    def test_local_crud(self):
        uid = self.backend.call({"op": "create", "event": {
            "title": "晨跑", "date": "2026-11-08", "startMin": 420, "endMin": 465,
            "location": "河濱", "repeat": "DAILY"}})["uid"]
        events = self.backend.range("2026-11-08", "2026-11-11")
        self.assertEqual([(e["date"], e["startMin"], e["endMin"]) for e in events],
                         [("2026-11-08", 420, 465), ("2026-11-09", 420, 465), ("2026-11-10", 420, 465)])
        self.assertTrue(all(e["recurring"] and not e["readOnly"] and e["calendar"] == "local" for e in events))

        loaded = self.backend.call({"op": "get", "uid": uid})["event"]
        self.assertEqual((loaded["title"], loaded["repeat"], loaded["startMin"], loaded["location"]),
                         ("晨跑", "DAILY", 420, "河濱"))

        self.backend.call({"op": "update", "uid": uid, "event": {
            "title": "晨泳", "date": "2026-11-09", "allDay": True, "repeat": ""}})
        events = self.backend.range("2026-11-08", "2026-11-11")
        self.assertEqual([(e["date"], e["title"], e["allDay"]) for e in events], [("2026-11-09", "晨泳", True)])

        self.backend.call({"op": "delete", "uid": uid})
        self.assertEqual(self.backend.range("2026-11-08", "2026-11-11"), [])

    def test_validation_errors(self):
        for event in ({"title": "", "date": "2026-11-08"},
                      {"title": "x", "date": "2026-11-08", "startMin": 600, "endMin": 600},
                      {"title": "x", "date": "2026-11-08", "repeat": "HOURLY"}):
            error = self.backend.call({"op": "create", "event": event}, "error")
            self.assertEqual(error["request"], "create")
        self.assertEqual(self.backend.call({"op": "delete", "uid": "missing"}, "error")["request"], "delete")
        self.assertEqual(self.backend.call({"op": "subscribe", "name": "x", "url": "ftp://x"}, "error")["request"],
                         "subscribe")

    def test_subscription_sync(self):
        feed_dir = os.path.join(self.temp.name, "feed")
        os.makedirs(feed_dir)
        with open(os.path.join(feed_dir, "feed.ics"), "w", encoding="utf-8") as stream:
            stream.write(FEED)
        handler = functools.partial(QuietHandler, directory=feed_dir)
        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            base = f"http://127.0.0.1:{server.server_address[1]}"
            good = self.backend.call({"op": "subscribe", "name": "測試", "url": base + "/feed.ics"})["subscriptionId"]
            bad = self.backend.call({"op": "subscribe", "name": "壞的", "url": base + "/missing.ics"})["subscriptionId"]
            self.backend.wait("subscriptions", timeout=60, check=lambda m: all(
                i["lastSync"] or i["error"] for i in m["items"]) and len(m["items"]) == 2)
            items = {i["id"]: i for i in self.backend.call({"op": "subscriptions"})["items"]}
            self.assertTrue(items[good]["lastSync"] and not items[good]["error"])
            self.assertTrue(items[bad]["error"])

            config = os.path.join(self.temp.name, "state", "vdirsyncer.conf")
            self.assertEqual(os.stat(config).st_mode & 0o777, 0o600)

            events = self.backend.range("2026-11-08", "2026-11-17")
            summary = sorted((e["date"], e["title"], e["startMin"], e["endMin"], e["allDay"]) for e in events)
            self.assertEqual(summary, [
                ("2026-11-08", "夜車", 1380, 1440, False),
                ("2026-11-09", "夜車", 0, 90, False),
                ("2026-11-10", "連假", 0, 1440, True),
                ("2026-11-11", "連假", 0, 1440, True),
                ("2026-11-16", "週會", 600, 690, False),  # 02:00Z -> 10:00 Taipei; 11/09 is EXDATE
            ])
            self.assertTrue(all(e["readOnly"] and e["calendarName"] == "測試" for e in events))
            self.assertEqual({e["title"]: e["recurring"] for e in events}, {"夜車": False, "連假": False, "週會": True})
            self.assertTrue(next(e for e in events if e["title"] == "夜車")["multiDay"])

            self.backend.send({"op": "unsubscribe", "subscriptionId": good})
            self.backend.wait("changed")
            self.assertEqual(self.backend.range("2026-11-08", "2026-11-17"), [])
            self.assertFalse(os.path.exists(os.path.join(self.temp.name, "data", good)))
        finally:
            server.shutdown()
            server.server_close()


if __name__ == "__main__":
    unittest.main(verbosity=2)
