#!/usr/bin/env bash
set -euo pipefail

config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/quickshell-notifications.XXXXXX")
trap 'rm -rf -- "$test_dir"' EXIT
mkdir -m 700 "$test_dir/runtime"
python - "$config_dir" "$test_dir/config" <<'PY'
import shutil
import sys
shutil.copytree(sys.argv[1], sys.argv[2], symlinks=False,
                ignore=shutil.ignore_patterns('.qmlls.ini', '.git', '.agents', '.codex'))
PY
# A private bus keeps the test notification server separate from the desktop.
if ! dbus-run-session -- env XDG_RUNTIME_DIR="$test_dir/runtime" \
    XDG_STATE_HOME="$test_dir/state" WAYLAND_DISPLAY= QT_QPA_PLATFORM=offscreen \
    timeout 15s qs -p "$test_dir/config/notification-tests.qml" --no-color > "$test_dir/log" 2>&1; then
    cat "$test_dir/log"
    exit 1
fi
cat "$test_dir/log"
if rg -q 'FAIL:|ERROR|TypeError|ReferenceError' "$test_dir/log"; then exit 1; fi
rg -q 'PASS: notification checks' "$test_dir/log"
if ! dbus-run-session -- env XDG_RUNTIME_DIR="$test_dir/runtime" \
    XDG_STATE_HOME="$test_dir/state" WAYLAND_DISPLAY= QT_QPA_PLATFORM=offscreen \
    NOTIFICATION_HISTORY_RELOAD=1 \
    timeout 15s qs -p "$test_dir/config/notification-tests.qml" --no-color > "$test_dir/reload-log" 2>&1; then
    cat "$test_dir/reload-log"
    exit 1
fi
cat "$test_dir/reload-log"
if rg -q 'FAIL:|ERROR|TypeError|ReferenceError' "$test_dir/reload-log"; then exit 1; fi
rg -q 'PASS: notification history reload' "$test_dir/reload-log"

if ! dbus-run-session -- env XDG_RUNTIME_DIR="$test_dir/runtime" \
    XDG_STATE_HOME="$test_dir/state" WAYLAND_DISPLAY= QT_QPA_PLATFORM=offscreen \
    timeout 8s qs -p "$test_dir/config/notification-scroll-tests.qml" --no-color > "$test_dir/scroll-log" 2>&1; then
    cat "$test_dir/scroll-log"
    exit 1
fi
cat "$test_dir/scroll-log"
if rg -q 'FAIL:|ERROR|TypeError|ReferenceError' "$test_dir/scroll-log"; then exit 1; fi
rg -q 'PASS: smooth scroll recovery' "$test_dir/scroll-log"
rg -q 'PASS: top-down expansion with fixed viewport' "$test_dir/scroll-log"
rg -q 'PASS: bottom-up collapse retains earlier notifications' "$test_dir/scroll-log"
