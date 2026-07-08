{pkgs, ...}: let
  cursorWarp = pkgs.runCommandCC "cursor-warp" {} ''
    mkdir -p "$out/bin"
    clang -o "$out/bin/cursor-warp" ${./cursor-warp.m} \
      -framework AppKit \
      -framework CoreFoundation \
      -framework CoreGraphics \
      -Wall -O2
  '';
in {
  home.packages = [cursorWarp];

  launchd.agents.cursor-warp = {
    enable = true;
    config = {
      ProgramArguments = ["${cursorWarp}/bin/cursor-warp"];
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "/tmp/cursor-warp.stderr.log";
    };
  };
}
