#!/usr/bin/env bash
set -euo pipefail
config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d /tmp/quickshell-bridge-test.XXXXXX)
trap 'rm -rf -- "$test_dir"' EXIT
bash "$config_dir/inputmethod/bridge/build.sh" "$test_dir"
/usr/lib/qt6/moc "$config_dir/tests/bridge-test.cpp" -o "$test_dir/bridge-test.moc"
read -r -a qt_flags <<< "$(pkg-config --cflags --libs Qt6Core Qt6DBus)"
c++ -std=c++17 -fPIC -I "$test_dir" "$config_dir/tests/bridge-test.cpp" \
    "${qt_flags[@]}" -o "$test_dir/bridge-test"
env HYPRLAND_INSTANCE_SIGNATURE= dbus-run-session -- "$test_dir/bridge-test" "$test_dir/fcitx-panel-bridge"
