{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.mac-app-util.darwinModules.default
    ../../../modules/system/macos/core.nix
    ../../../modules/system/macos/homebrew.nix
    ../../../modules/system/macos/secrets.nix
  ];

  services.sketchybar = {
    enable = true;
    extraPackages = [pkgs.jq];
  };
}
