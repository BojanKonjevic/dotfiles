{inputs, ...}: {
  imports = [
    ../../../modules/system/nixos/core.nix
    ../../../modules/system/nixos/audio.nix
    ../../../modules/system/nixos/desktop.nix
    ../../../modules/system/nixos/display.nix
    ../../../modules/system/nixos/entry.nix
    ../../../modules/system/nixos/secrets.nix
    ../../../modules/system/nixos/impermanence.nix
    ../../../modules/system/nixos/wipe-root.nix
    inputs.impermanence.nixosModules.impermanence
    ../../../modules/system/nixos/luks.nix
  ];
}
