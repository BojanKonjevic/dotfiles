#!/usr/bin/env bash
emit_net() {
  nmcli -t -f TYPE,STATE dev status 2>/dev/null |
    awk -F: '$2=="connected" {print $1; exit}'
}

emit_net

nmcli monitor 2>/dev/null | while read -r line; do
  emit_net
done
