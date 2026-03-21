{pkgs, userConfig, ...}: {
  services.dbus.enable = true;
  security.polkit.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  programs.dconf.enable = true;
  networking.networkmanager.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 1;
  boot.loader.efi.canTouchEfiVariables = true;
  programs.zsh.enable = true;
  programs.ydotool.enable = true;
  users.users.${userConfig.username} = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = userConfig.fullName;
    extraGroups = ["networkmanager" "wheel" "audio" "input" "ydotool" "video"];
  };
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
}
