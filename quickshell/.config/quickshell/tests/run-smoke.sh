#!/usr/bin/env bash
set -euo pipefail

config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/quickshell-smoke.XXXXXX")
trap 'rm -rf -- "$test_dir"' EXIT
mkdir -m 700 "$test_dir/runtime"

# Copy the config without qmlls links so tests cannot fight the live shell's tooling.
python - "$config_dir" "$test_dir/config" <<'PY'
import shutil
import sys

shutil.copytree(sys.argv[1], sys.argv[2], symlinks=False,
                ignore=shutil.ignore_patterns('.qmlls.ini', '.git', '.agents', '.codex'))
PY

# Isolate usage counts and runtime sockets; never create desktop panel windows.
if ! env XDG_RUNTIME_DIR="$test_dir/runtime" XDG_STATE_HOME="$test_dir/state" \
    WAYLAND_DISPLAY= QT_QPA_PLATFORM=offscreen \
    timeout 15s qs -p "$test_dir/config/tests.qml" --no-color > "$test_dir/log" 2>&1; then
    cat "$test_dir/log"
    exit 1
fi
cat "$test_dir/log"
if rg -q 'FAIL:|Failed to load configuration|ERROR quickshell\.(tooling|ipc)' "$test_dir/log"; then
    exit 1
fi
rg -q 'PASS: modular shell smoke checks' "$test_dir/log"
python - "$test_dir/state" <<'PY'
import json
import sys
from pathlib import Path

files = list(Path(sys.argv[1]).rglob('launcher-usage.json'))
assert len(files) == 1, 'Usage file was not saved'
assert json.loads(files[0].read_text())['counts']['beta'] == 1, 'Usage count did not persist'
print('PASS: isolated usage persistence')
PY
