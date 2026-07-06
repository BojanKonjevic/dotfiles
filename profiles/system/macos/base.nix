{inputs, ...}: {
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ../../../modules/system/macos/core.nix
    ../../../modules/system/macos/homebrew.nix
    ../../../modules/system/macos/secrets.nix
    ../../../modules/system/macos/tailscale.nix
  ];
}
