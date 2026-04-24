{...}: {
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
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
  boot.kernelModules = [
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
  services.pipewire.wireplumber.extraConfig."10-default-sink" = {
    "wireplumber.settings"."default.audio.sink" = "alsa_output.pci-0000_00_1f.3.analog-stereo";
  };
}
