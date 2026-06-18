{
  inputs,
  userConfig,
  ...
}: let
  pkgs = inputs.nixpkgs.legacyPackages.${userConfig.system};
in {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ../../../modules/system/nixos/lanzaboote.nix
  ];
  environment.systemPackages = with pkgs; [qemu];
}
