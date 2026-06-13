#!/usr/bin/env bash
while true; do
  read -r _ u1 _ s1 i1 rest1 </proc/stat
  sleep 0.4
  read -r _ u2 _ s2 i2 rest2 </proc/stat

  used=$((u2 - u1 + s2 - s1))
  total=$((u2 - u1 + s2 - s1 + i2 - i1))
  cpu=$((total > 0 ? used * 100 / total : 0))

  mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print int((t-a)/t*100)}' /proc/meminfo)

  printf '{"cpu":%d,"mem":%d}\n' "$cpu" "$mem"
  sleep 1.6
done
