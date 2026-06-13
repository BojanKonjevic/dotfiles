#!/usr/bin/env bash
printf '%s' "$1" | cliphist decode | wl-copy
