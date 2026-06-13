{...}: let
  raycastConfigPath = "Library/Application Support/com.raycast.macOS/config.json";
  seedConfig = builtins.readFile ./config.json;
in {
  home.file."${raycastConfigPath}".text = seedConfig;
}
