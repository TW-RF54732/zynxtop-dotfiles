#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir=${1:?Usage: build.sh OUTPUT_DIRECTORY}
mkdir -p -- "$build_dir"
/usr/lib/qt6/moc "$source_dir/main.cpp" -o "$build_dir/main.moc"
read -r -a qt_flags <<< "$(pkg-config --cflags --libs Qt6Core Qt6DBus)"
c++ -std=c++17 -O2 -fPIC -Wall -Wextra -I "$build_dir" "$source_dir/main.cpp" \
    "${qt_flags[@]}" -o "$build_dir/fcitx-panel-bridge"
