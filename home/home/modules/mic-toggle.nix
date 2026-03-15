{pkgs, ...}: let
  muteSound = pkgs.runCommand "mic-mute-sound" {buildInputs = [pkgs.sox];} ''
    mkdir -p $out
    sox -n -r 48000 -c 2 /tmp/a.wav synth 0.11 sine 880 fade l 0.005 0.11 0.03 vol 0.10
    sox -n -r 48000 -c 2 /tmp/b.wav synth 0.14 sine 600 fade l 0.005 0.14 0.06 vol 0.10
    sox /tmp/a.wav /tmp/b.wav $out/mute.wav
  '';

  unmuteSound = pkgs.runCommand "mic-unmute-sound" {buildInputs = [pkgs.sox];} ''
    mkdir -p $out
    sox -n -r 48000 -c 2 /tmp/a.wav synth 0.11 sine 600 fade l 0.005 0.11 0.03 vol 0.10
    sox -n -r 48000 -c 2 /tmp/b.wav synth 0.14 sine 880 fade l 0.005 0.14 0.06 vol 0.10
    sox /tmp/a.wav /tmp/b.wav $out/unmute.wav
  '';

  micToggle = pkgs.writeShellScriptBin "mic-toggle" ''
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
      pw-play ${muteSound}/mute.wav &
    else
      pw-play ${unmuteSound}/unmute.wav &
    fi
  '';
in {
  home.packages = [micToggle];
}
