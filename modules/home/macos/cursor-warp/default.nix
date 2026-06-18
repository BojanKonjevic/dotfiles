{pkgs, ...}: let
  frameworks = with pkgs.darwin.apple_sdk.frameworks; [AppKit Foundation];
  cursorWarp = pkgs.stdenv.mkDerivation {
    name = "cursor-warp";
    src = ./CursorWarp.swift;
    nativeBuildInputs = with pkgs; [swift];
    buildInputs = frameworks;
    buildPhase = ''
      swiftc -o cursor-warp "$src" \
        -F${pkgs.darwin.apple_sdk.frameworks.AppKit}/Library/Frameworks \
        -F${pkgs.darwin.apple_sdk.frameworks.Foundation}/Library/Frameworks
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
    };
  };
}
