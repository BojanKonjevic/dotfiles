{
  pkgs,
  inputs,
  userConfig,
  ...
}: {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ../../../modules/system/nixos/lanzaboote.nix
  ];
  environment.systemPackages = with pkgs; [qemu];
}
