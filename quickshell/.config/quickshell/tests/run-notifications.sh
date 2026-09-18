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
