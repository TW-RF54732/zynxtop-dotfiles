#!/usr/bin/env bash
# Briefly opens a real overlay. Run from an active Hyprland session.
set -euo pipefail
config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/quickshell-sidebar-wayland.XXXXXX")
trap 'rm -rf -- "$test_dir"' EXIT
python - "$config_dir" "$test_dir/config" <<'PY'
import shutil
import sys
shutil.copytree(sys.argv[1], sys.argv[2], symlinks=False,
                ignore=shutil.ignore_patterns('.qmlls.ini', '.git', '.agents', '.codex'))
PY
if ! dbus-run-session -- env XDG_STATE_HOME="$test_dir/state" QT_QPA_PLATFORMTHEME=generic \
    timeout 20s qs -p "$test_dir/config/sidebar-window-tests.qml" --no-color > "$test_dir/log" 2>&1; then
    cat "$test_dir/log"
    exit 1
fi
cat "$test_dir/log"
if rg -q 'FAIL!|FAIL:|ERROR|TypeError|ReferenceError|Binding loop' "$test_dir/log"; then exit 1; fi
rg -q 'PASS: sidebar Wayland click and keyboard checks' "$test_dir/log"
