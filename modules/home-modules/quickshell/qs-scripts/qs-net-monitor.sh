{pkgs}: ''
  emit_net() {
    ${pkgs.networkmanager}/bin/nmcli -t -f TYPE,STATE dev status 2>/dev/null \
      | awk -F: '$2=="connected" {print $1; exit}'
  }

  # emit immediately on start
  emit_net

  # re-emit on every nmcli connectivity change
  ${pkgs.networkmanager}/bin/nmcli monitor 2>/dev/null | while read -r line; do
    emit_net
  done
''
