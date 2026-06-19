{pkgs, ...}: let
  cursorWarp = pkgs.stdenv.mkDerivation {
    name = "cursor-warp";
    src = ./CursorWarp.swift;
    nativeBuildInputs = with pkgs; [swift];
    buildInputs = with pkgs; [apple-sdk_15];
    buildPhase = ''
      swiftc -o cursor-warp "$src" \
        -framework AppKit \
        -framework Foundation
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp cursor-warp $out/bin/
    '';
  };
in {
  home.packages = [cursorWarp];

  launchd.agents.cursor-warp = {
    enable = true;
    config = {
      ProgramArguments = ["${cursorWarp}/bin/cursor-warp"];
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
