{pkgs, ...}: {
  boot.initrd.luks.devices = {
    "cryptroot" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      allowDiscards = true;
      crypttabExtraOpts = ["tpm2-device=auto" "tpm2-pcrs=0+7"];
    };
  };

  # TPM kernel modules
  boot.initrd.kernelModules = ["tpm_tis" "tpm_crb"];

  # tpm2-tss must be available inside the initrd for systemd-cryptsetup to use it
  boot.initrd.systemd.packages = [pkgs.tpm2-tss];

  # enroll/inspect tool available in the booted system
  environment.systemPackages = [pkgs.tpm2-tools];
}
