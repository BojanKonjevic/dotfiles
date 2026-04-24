#!/usr/bin/env bash
find "${WALLPAPER_DIR}" -maxdepth 1 -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) |
  sort |
  while read -r f; do
    printf '{"name":"%s","path":"file://%s"}\n' "$(basename "$f")" "$f"
  done
