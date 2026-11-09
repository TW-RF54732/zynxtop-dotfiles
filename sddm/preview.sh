#!/usr/bin/env bash
# Preview the theme without root: builds a temp copy and opens the greeter in test mode.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WALLPAPER="${WALLPAPER:-/home/lolleo/Pictures/Wallpapers/pexels-nathanmarcam-10558778.jpg}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/lolleo/Backgrounds"
cp "$HERE"/theme/{Main.qml,metadata.desktop,theme.conf} "$TMP/lolleo/"
"$HERE/make-backgrounds.sh" "$WALLPAPER" "$TMP/lolleo/Backgrounds"
# xcb: on Wayland, Qt gives opaque windows a 16-bit (RGB565) buffer, which tints dark colours green.
# The real SDDM greeter runs on Xorg (24-bit), so xcb previews it accurately.
QT_QPA_PLATFORM=xcb sddm-greeter-qt6 --test-mode --theme "$TMP/lolleo"
