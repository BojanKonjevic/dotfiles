{lib, ...}: {
  boot.loader.systemd-boot.enable = lib.mkOverride 0 true;
  boot.loader.efi.canTouchEfiVariables = lib.mkOverride 0 true;
  boot.lanzaboote.enable = lib.mkOverride 0 false;
}
