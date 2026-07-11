#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Private Zen Search
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔍
# @raycast.argument1 { "type": "text", "placeholder": "search term" }
# @raycast.packageName Zen

# Documentation:
# @raycast.description Open a search query in a new private Zen window
# @raycast.author bojan

urlencode() {
  local s="$1" out="" c i
  for ((i = 0; i < ${#s}; i++)); do
    c="${s:i:1}"
    case "$c" in
    [a-zA-Z0-9.~_-]) out+="$c" ;;
    ' ') out+="+" ;;
    *)
      printf -v hex '%%%02X' "'$c"
      out+="$hex"
      ;;
    esac
  done
  echo "$out"
}

QUERY="$1"

# Detect if input looks like a URL/domain rather than a search term:
# - starts with a scheme (http://, https://, etc.)
# - or looks like "word.word" / "word.word/..." with no spaces (e.g. github.com, foo.bar/baz)
if [[ "$QUERY" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:// ]]; then
  URL="$QUERY"
elif [[ "$QUERY" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ ]] && [[ "$QUERY" != *" "* ]]; then
  URL="https://$QUERY"
else
  ENCODED_QUERY=$(urlencode "$QUERY")
  URL="https://www.google.com/search?q=${ENCODED_QUERY}&hl=en&gl=us"
fi

ZEN_BIN="/Users/bojan/Applications/Home Manager Apps/Zen Browser (Beta).app/Contents/MacOS/zen"

"$ZEN_BIN" -private-window "$URL"
