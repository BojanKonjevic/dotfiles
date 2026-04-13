#!/usr/bin/env bash
cliphist list | while IFS=$'\t' read -r id content; do
  [[ $content == *"[[ binary data"* ]] && continue
  printf '%s\t%s' "$id" "$content" | cliphist delete
done
