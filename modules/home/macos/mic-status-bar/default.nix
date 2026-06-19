{
  pkgs,
  config,
  ...
}: let
  micStatusBar = pkgs.stdenv.mkDerivation {
    name = "mic-status-bar";
    src = ./MicStatusBar.swift;
    nativeBuildInputs = with pkgs; [swift];
    buildInputs = with pkgs; [apple-sdk_15];
    buildPhase = ''
      swiftc -o mic-status-bar "$src" \
        -framework AppKit \
        -framework Foundation
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
      EnvironmentVariables = {
        MIC_TOGGLE_PATH = "${config.home.profileDirectory}/bin/mic-toggle";
      };
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
