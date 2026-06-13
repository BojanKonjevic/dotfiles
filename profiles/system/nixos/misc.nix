{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ../../../modules/system/nixos/lanzaboote.nix
    ../../../modules/system/nixos/restic.nix
  ];
  environment.systemPackages = with pkgs; [
    qemu
  ];
}
