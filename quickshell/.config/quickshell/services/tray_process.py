"""Terminate the process that owns a StatusNotifierItem.

Usage: tray_process.py <item-id> [<title>]
Prints one JSON object: {"ok": bool, "pid": int, "name": str, "error": str}.
Quickshell does not expose the item's D-Bus owner, so the owner is resolved
through the watcher's registered item list and the bus daemon's PID lookup.
"""
import json
import os
import signal
import subprocess
import sys

WATCHER = ('org.kde.StatusNotifierWatcher', '/StatusNotifierWatcher', 'org.kde.StatusNotifierWatcher')
ITEM_INTERFACES = ('org.kde.StatusNotifierItem', 'org.freedesktop.StatusNotifierItem')


def busctl(*args):
    try:
        result = subprocess.run(['busctl', '--user', '--json=short', *args],
                                capture_output=True, text=True, timeout=3)
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout).get('data')
    except ValueError:
        return None


def item_property(service, path, name):
    for interface in ITEM_INTERFACES:
        value = busctl('get-property', service, path, interface, name)
        if value is not None:
            return value
    return None


def registered_items():
    items = busctl('get-property', *WATCHER, 'RegisteredStatusNotifierItems') or []
    for entry in items:
        slash = entry.find('/')
        if slash < 0:
            yield entry, '/StatusNotifierItem'
        elif slash > 0:
            yield entry[:slash], entry[slash:]


def owner_pid(service):
    data = busctl('call', 'org.freedesktop.DBus', '/org/freedesktop/DBus', 'org.freedesktop.DBus',
                  'GetConnectionUnixProcessID', 's', service)
    return int(data[0]) if data else 0


def process_name(pid):
    try:
        with open(f'/proc/{pid}/comm') as handle:
            return handle.read().strip()
    except OSError:
        return ''


def find_pid(item_id, title):
    fallback = 0
    for service, path in registered_items():
        if item_property(service, path, 'Id') != item_id:
            continue
        pid = owner_pid(service)
        if not pid:
            continue
        if not title or item_property(service, path, 'Title') == title:
            return pid
        fallback = fallback or pid
    return fallback


def main():
    item_id = sys.argv[1] if len(sys.argv) > 1 else ''
    title = sys.argv[2] if len(sys.argv) > 2 else ''
    reply = dict(ok=False, pid=0, name='', error='')
    pid = find_pid(item_id, title) if item_id else 0
    reply['pid'] = pid
    reply['name'] = process_name(pid) if pid else ''
    # Never signal init, this helper, or the shell that launched it.
    if pid <= 1 or pid in (os.getpid(), os.getppid()):
        reply['error'] = 'PROCESS NOT FOUND' if pid == 0 else 'REFUSED'
    else:
        try:
            os.kill(pid, signal.SIGTERM)
            reply['ok'] = True
        except OSError as exception:
            reply['error'] = exception.strerror or 'FAILED'
    print(json.dumps(reply), flush=True)


if __name__ == '__main__':
    main()
