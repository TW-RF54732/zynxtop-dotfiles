#!/usr/bin/env bash
# make-backgrounds.sh <wallpaper> <out-dir>: wallpaper fitted to 3440x1440 and slightly dimmed.
set -euo pipefail
src=$1 out=$2
mkdir -p "$out"
magick "$src" -resize 3440x1440^ -gravity center -extent 3440x1440 \
    -depth 16 -evaluate Multiply 0.72 -quality 95 "$out/lolleo.jpg"
