#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir=${1:?Usage: ensure.sh BUILD_DIRECTORY}
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then exit 0; fi
if hyprctl -j quickshell-caret 2>/dev/null | rg -q '"valid"'; then exit 0; fi
mkdir -p -- "$build_dir"
read -r -a hypr_flags <<< "$(pkg-config --cflags hyprland)"
# Use the installed development headers and enforce their commit hash on load.
c++ -std=c++23 -O2 -shared -fPIC "$source_dir/main.cpp" \
    "${hypr_flags[@]}" -o "$build_dir/libquickshell-caret.so"
load_reply=$(hyprctl plugin load "$build_dir/libquickshell-caret.so")
if [[ "$load_reply" != "ok" ]]; then printf '%s\n' "$load_reply" >&2; exit 1; fi
hyprctl -j quickshell-caret | rg -q '"valid"'
