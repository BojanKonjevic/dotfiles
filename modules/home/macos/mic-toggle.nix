{pkgs, ...}: let
  micToggle = pkgs.writeShellScriptBin "mic-toggle" ''
    CURRENT=$(osascript -e "input volume of (get volume settings)")
    if [ "$CURRENT" -eq 0 ]; then
      osascript -e "set volume input volume 100"
      echo "unmuted" > /tmp/qs-mic-state
    else
      osascript -e "set volume input volume 0"
      echo "muted" > /tmp/qs-mic-state
    fi
  '';
in {
  home.packages = [micToggle];
}
