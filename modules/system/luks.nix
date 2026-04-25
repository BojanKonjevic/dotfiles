{
  userConfig,
  lib,
  ...
}: {
  boot.initrd.luks.devices =
    {
      "cryptroot" = {
        device = "/dev/disk/by-partlabel/disk-main-root";
        allowDiscards = true;
      };
    }
    // lib.optionalAttrs (userConfig.homeDisk != "") {
      "crypthome" = {
        device = "/dev/disk/by-partlabel/disk-main-home";
        allowDiscards = true;
      };
    };
}
