{pkgs, lib, ...}: let
  name = "cursor-warp";
  binary = pkgs.runCommandCC name {} ''
    mkdir -p "$out/bin"
    clang -o "$out/bin/${name}" ${./${name}.m} \
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
