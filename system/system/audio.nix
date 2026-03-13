{...}: {
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  boot.kernelModules = [
    "uinput"
    "snd_hda_intel"
    "snd_hda_codec_realtek"
  ];

  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="input"
  '';

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

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };
}
