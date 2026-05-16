{pkgs, ...}: let
  micToggle = pkgs.writeShellScriptBin "mic-toggle" ''
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
      echo "muted" > /tmp/qs-mic-state.tmp && mv /tmp/qs-mic-state.tmp /tmp/qs-mic-state
      ${pkgs.sox}/bin/sox ${../../lib/mute.mp3} -t wav - vol 0.25 | pw-play -
    else
      echo "unmuted" > /tmp/qs-mic-state.tmp && mv /tmp/qs-mic-state.tmp /tmp/qs-mic-state
      ${pkgs.sox}/bin/sox ${../../lib/unmute.mp3} -t wav - vol 0.17 | pw-play -
    fi
  '';
in {
  home.packages = [micToggle];
}
