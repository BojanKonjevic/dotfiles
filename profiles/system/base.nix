{
  inputs,
  lib,
  userConfig,
  ...
}: let
  isDarwin = userConfig.system == "aarch64-darwin";
in {
  imports =
    lib.optionals isDarwin [
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.mac-app-util.darwinModules.default
      ../../modules/system/macos/core.nix
      ../../modules/system/macos/homebrew.nix
      ../../modules/system/macos/secrets.nix
    ]
    ++ lib.optionals (!isDarwin) [
      ../../modules/system/nixos/core.nix
      ../../modules/system/nixos/audio.nix
      ../../modules/system/nixos/desktop.nix
      ../../modules/system/nixos/display.nix
      ../../modules/system/nixos/entry.nix
      ../../modules/system/nixos/secrets.nix
      ../../modules/system/nixos/impermanence.nix
      ../../modules/system/nixos/wipe-root.nix
      inputs.impermanence.nixosModules.impermanence
      ../../modules/system/nixos/luks.nix
    ];
}
