nmcli -t -f TYPE,STATE dev status 2>/dev/null \
  | awk -F: '$2=="connected" {print $1; exit}'
