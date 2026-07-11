{
  userConfig,
  lib,
  ...
}: let
  raycastConfigPath = "Library/Application Support/com.raycast.macOS/config.json";
in {
  homebrew.casks = ["raycast"];

  home-manager.users.${userConfig.username}.home.activation.raycastSeed = lib.mkAfter ''
    if [ ! -f "$HOME/${raycastConfigPath}" ]; then
      mkdir -p "$HOME/Library/Application Support/com.raycast.macOS"
      cp ${./config.json} "$HOME/${raycastConfigPath}"
    fi
  '';
}
