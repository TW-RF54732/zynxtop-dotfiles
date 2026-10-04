#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir=${1:?Usage: run.sh BUILD_DIRECTORY}
if ! bash "$source_dir/../hyprland-caret/ensure.sh" "$build_dir/caret"; then
    printf 'Native Wayland caret adapter unavailable; direct cursor coordinates remain supported\n' >&2
fi
if [[ ! -x "$build_dir/fcitx-panel-bridge" || "$source_dir/main.cpp" -nt "$build_dir/fcitx-panel-bridge" || "$source_dir/build.sh" -nt "$build_dir/fcitx-panel-bridge" ]]; then
    bash "$source_dir/build.sh" "$build_dir"
fi
exec "$build_dir/fcitx-panel-bridge"
