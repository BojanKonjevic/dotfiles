{lib, ...}: let
  raycastConfigPath = "Library/Application Support/com.raycast.macOS/config.json";
in {
  home.activation.raycastSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/${raycastConfigPath}" ]; then
      mkdir -p "$HOME/Library/Application Support/com.raycast.macOS"
      cp ${./config.json} "$HOME/${raycastConfigPath}"
    fi
  '';
}
