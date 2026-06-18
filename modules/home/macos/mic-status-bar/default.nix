{pkgs, ...}: let
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

  launchd.agents.mic-status-bar = {
    enable = true;
    config = {
      ProgramArguments = ["${micStatusBar}/bin/mic-status-bar"];
      KeepAlive = true;
    };
  };
}
