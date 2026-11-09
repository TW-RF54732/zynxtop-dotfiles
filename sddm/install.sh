#!/usr/bin/env bash
# Install the custom SDDM theme to /usr/share/sddm/themes/lolleo (run with sudo).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DEST=/usr/share/sddm/themes/lolleo
WALLPAPER="${WALLPAPER:-/home/lolleo/Pictures/Wallpapers/pexels-nathanmarcam-10558778.jpg}"

[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }

install -d -m755 "$DEST/Backgrounds"
install -m644 "$HERE"/theme/{Main.qml,metadata.desktop,theme.conf} "$DEST/"
"$HERE/make-backgrounds.sh" "$WALLPAPER" "$DEST/Backgrounds"

install -d /etc/sddm.conf.d
printf '[Theme]\nCurrent=lolleo\n' > /etc/sddm.conf.d/theme.conf
echo "installed: $DEST"
