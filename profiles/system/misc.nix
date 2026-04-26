{inputs, ...}: {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ../../modules/system/lanzaboote.nix
    ../../modules/system/postgres.nix
    ../../modules/system/restic.nix
  ];
}
