{
  pkgs,
  config,
  ...
}: let
  micStatusBar = pkgs.runCommand "mic-status-bar" {} ''
    unset SDKROOT DEVELOPER_DIR
    mkdir -p "$out/bin"
    /usr/bin/clang -o "$out/bin/mic-status-bar" ${./mic-status-bar.m} \
      -framework AppKit \
      -framework CoreAudio \
      -framework Carbon \
      -framework AudioUnit \
      -framework Foundation \
      -Wall -O2
    cp ${../../../../lib/mute.mp3} "$out/bin/mute.mp3"
    cp ${../../../../lib/unmute.mp3} "$out/bin/unmute.mp3"
  '';
in {
  home.packages = [micStatusBar];

  launchd.agents.mic-status-bar = {
    enable = true;
    config = {
      ProgramArguments = ["${micStatusBar}/bin/mic-status-bar"];
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "/tmp/mic-status-bar.stderr.log";
    };
  };
}
