{
  pkgs,
  lib,
  ...
}: let
  name = "cursor-warp";
  binary = pkgs.runCommand "cursor-warp" {} ''
    unset SDKROOT DEVELOPER_DIR
    mkdir -p "$out/bin"
    /usr/bin/clang -o "$out/bin/cursor-warp" ${./cursor-warp.m} \
      -framework AppKit \
      -framework CoreFoundation \
      -framework CoreGraphics \
      -Wall -O2
  '';
in {
  home.packages = [binary];

  launchd.agents.cursor-warp = {
    enable = true;
    config = {
      ProgramArguments = ["${binary}/bin/${name}"];
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "/tmp/cursor-warp.stderr.log";
    };
  };
}
