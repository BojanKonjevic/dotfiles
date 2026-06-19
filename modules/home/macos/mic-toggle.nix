{pkgs, ...}: let
  micToggle = pkgs.writeShellScriptBin "mic-toggle" ''
    CURRENT=$(osascript -e "input volume of (get volume settings)")
    if [ "$CURRENT" -eq 0 ]; then
      PREV=$(cat /tmp/qs-mic-prev-volume 2>/dev/null || echo "100")
      osascript -e "set volume input volume $PREV"
      echo "unmuted" > /tmp/qs-mic-state.tmp
      mv /tmp/qs-mic-state.tmp /tmp/qs-mic-state
    else
      echo "$CURRENT" > /tmp/qs-mic-prev-volume.tmp
      mv /tmp/qs-mic-prev-volume.tmp /tmp/qs-mic-prev-volume
      osascript -e "set volume input volume 0"
      echo "muted" > /tmp/qs-mic-state.tmp
      mv /tmp/qs-mic-state.tmp /tmp/qs-mic-state
    fi
  '';
in {
  home.packages = [micToggle];
}
