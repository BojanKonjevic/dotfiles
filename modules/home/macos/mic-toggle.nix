{pkgs, ...}: let
  micToggle = pkgs.runCommandCC "mic-toggle" {} ''
    mkdir -p "$out/bin"
    clang -o "$out/bin/mic-toggle" ${./mic-toggle.m} \
      -framework CoreAudio \
      -framework Foundation \
      -Wall -O2
    cp ${../../../lib/mute.mp3} "$out/bin/mute.mp3"
    cp ${../../../lib/unmute.mp3} "$out/bin/unmute.mp3"
  '';
in {
  home.packages = [micToggle];
}
