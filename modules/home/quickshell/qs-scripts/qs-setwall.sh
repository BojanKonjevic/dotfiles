#!/usr/bin/env bash
[[ -z $1 ]] && exit 0
[[ ! -f $1 ]] && exit 1
awww img "$1" \
  --transition-type wipe \
  --transition-angle 30 \
  --transition-duration 0.8 \
  --transition-fps 60
ln -sf "$1" "${WALLPAPER_DIR}/wall.jpg"
