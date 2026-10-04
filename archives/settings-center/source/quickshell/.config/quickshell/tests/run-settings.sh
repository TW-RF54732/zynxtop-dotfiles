#!/usr/bin/env bash
set -euo pipefail
config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/settings-tests.XXXXXX")
trap 'rm -rf -- "$test_dir"' EXIT
mkdir -m 700 "$test_dir/runtime"
python3 -B "$config_dir/settings/test_backend.py"
if ! env XDG_CONFIG_HOME="$test_dir/config" XDG_RUNTIME_DIR="$test_dir/runtime" XDG_STATE_HOME="$test_dir/state" \
    WAYLAND_DISPLAY= QT_QPA_PLATFORM=offscreen timeout 20s qs -p "$config_dir/settings-tests.qml" --no-color > "$test_dir/log" 2>&1; then
    cat "$test_dir/log"; exit 1
fi
cat "$test_dir/log"
if rg -q 'FAIL:|Failed to load configuration|ReferenceError|TypeError|Binding loop' "$test_dir/log"; then exit 1; fi
rg -q 'PASS: settings window and backend loaded' "$test_dir/log"
test ! -e "$test_dir/config/settings-center/settings.json"
