{...}: {
  flake.nixosModules.hardware = {
    config,
    lib,
    modulesPath,
    ...
  }: {
    imports = [(modulesPath + "/installer/scan/not-detected.nix")];
    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    boot.initrd.kernelModules = [];
    boot.extraModulePackages = [];
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/8ae2154a-f57e-4ded-9131-92d3547648c6";
      fsType = "ext4";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/2CF2-3DDE";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    fileSystems."/home" = {
      device = "/dev/disk/by-uuid/c51a1808-a748-432b-a041-44672dec2412";
      fsType = "ext4";
    };
    swapDevices = [{device = "/dev/disk/by-uuid/a20a6b48-b4e7-4856-8d6d-5367803c2b57";}];
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    boot.kernelModules = [
      "kvm-intel"
      "uinput"
      "snd_hda_intel"
      "snd_hda_codec_realtek"
    ];
    boot.blacklistedKernelModules = [
      "snd_sof_pci_intel_cnl"
      "snd_sof_intel_hda_generic"
      "snd_sof_intel_hda_common"
      "snd_sof"
      "snd_soc_avs"
      "snd_sof_pci"
      "snd_sof_intel_hda"
      "snd_sof_intel_hda_mlink"
      "snd_soc_hdac_hda"
    ];
    boot.extraModprobeConfig = ''
      softdep snd_sof pre: snd_hda_intel snd_hda_codec_realtek
      options snd-intel-dspcfg dsp_driver=1
      options snd-hda-intel model=auto
    '';
    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="input"
    '';
    services.pipewire.wireplumber.extraConfig."10-default-sink" = {
      "wireplumber.settings"."default.audio.sink" = "alsa_output.pci-0000_00_1f.3.analog-stereo";
    };
  };
}
