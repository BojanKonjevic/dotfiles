{
  userConfig,
  lib,
  ...
}: {
  boot.initrd.luks.devices =
    {
      "cryptroot" = {
        device = "/dev/disk/by-partlabel/root";
        allowDiscards = true;
      };
    }
    // lib.optionalAttrs (userConfig.homeDisk != "") {
      "crypthome" = {
        device = "/dev/disk/by-partlabel/home";
        allowDiscards = true;
      };
    };
}
