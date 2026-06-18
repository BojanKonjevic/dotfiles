{pkgs, ...}: let
  frameworks = with pkgs.darwin.apple_sdk.frameworks; [AppKit Foundation];
  micStatusBar = pkgs.stdenv.mkDerivation {
    name = "mic-status-bar";
    src = ./MicStatusBar.swift;
    nativeBuildInputs = with pkgs; [swift];
    buildInputs = frameworks;
    buildPhase = ''
      swiftc -o mic-status-bar "$src" \
        -F${pkgs.darwin.apple_sdk.frameworks.AppKit}/Library/Frameworks \
        -F${pkgs.darwin.apple_sdk.frameworks.Foundation}/Library/Frameworks
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
