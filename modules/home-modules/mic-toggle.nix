{...}: {
  flake.homeModules.mic-toggle = {pkgs, ...}: let
    micToggle = pkgs.writeShellScriptBin "mic-toggle" ''
      wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
        ${pkgs.sox}/bin/sox ${./files/mute.mp3} -t wav - vol 0.25 | pw-play -
      else
        ${pkgs.sox}/bin/sox ${./files/unmute.mp3} -t wav - vol 0.17 | pw-play -
      fi
    '';
  in {
    home.packages = [micToggle];
  };
}
