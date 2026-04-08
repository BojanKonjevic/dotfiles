#!/usr/bin/env bash
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-qs"
mkdir -p "$CACHE_DIR"
mapfile -t live_ids < <(cliphist list | awk -F'\t' '{print $1}')
for f in "$CACHE_DIR"/*.png; do
  [[ -f "$f" ]] || continue
  id="${f##*/}"; id="${id%.png}"
  printf '%s\n' "${live_ids[@]}" | grep -qx "$id" || rm -f "$f"
done
while IFS=$'\t' read -r id content; do
  [[ "$content" == *"[[ binary data"* ]] || continue
  img="$CACHE_DIR/${id}.png"
  if [[ ! -s "$img" ]]; then
    printf '%s\t%s' "$id" "$content" | cliphist decode > "$img" 2>/dev/null
  fi
  [[ -s "$img" ]] || continue
  printf '{"id":"%s","content":"%s","path":"file://%s"}\n' "$id" "$content" "$img"
done < <(cliphist list)
