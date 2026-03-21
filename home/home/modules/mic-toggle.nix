{pkgs, ...}: let
  micToggle = pkgs.writeShellScriptBin "mic-toggle" ''
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
      pw-play <(sox ${./files/mute.mp3} -t wav - vol 0.25) &
    else
      pw-play <(sox ${./files/unmute.mp3} -t wav - vol 0.17) &
    fi
  '';
in {
  home.packages = [micToggle];
}
