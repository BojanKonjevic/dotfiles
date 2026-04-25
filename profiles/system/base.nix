{inputs, ...}: {
  imports = [
    ../../modules/system/core.nix
    ../../modules/system/audio.nix
    ../../modules/system/desktop.nix
    ../../modules/system/display.nix
    ../../modules/system/entry.nix
    ../../modules/system/secrets.nix
    ../../modules/system/impermanence.nix
    ../../modules/system/wipe-root.nix
    inputs.impermanence.nixosModules.impermanence
  ];
}
