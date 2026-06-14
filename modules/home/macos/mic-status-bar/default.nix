{
  pkgs,
  config,
  lib,
  ...
}: let
  micStatusBar = pkgs.stdenv.mkDerivation {
    name = "mic-status-bar";
    src = ./MicStatusBar.swift;
    nativeBuildInputs = with pkgs; [swift];
    buildPhase = ''
      swiftc -o mic-status-bar "$src"
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp mic-status-bar $out/bin/
    '';
  };
in {
  home.packages = [micStatusBar];

  launchd.user.agents.mic-status-bar = {
    enable = true;
    command = "${micStatusBar}/bin/mic-status-bar";
    keepAlive = true;
  };
}
