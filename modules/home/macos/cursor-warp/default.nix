{
  pkgs,
  config,
  lib,
  ...
}: let
  cursorWarp = pkgs.stdenv.mkDerivation {
    name = "cursor-warp";
    src = ./CursorWarp.swift;
    nativeBuildInputs = with pkgs; [swift];
    buildPhase = ''
      swiftc -o cursor-warp "$src"
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp cursor-warp $out/bin/
    '';
  };
in {
  home.packages = [cursorWarp];

  launchd.user.agents.cursor-warp = {
    enable = true;
    command = "${cursorWarp}/bin/cursor-warp";
    keepAlive = true;
  };
}
