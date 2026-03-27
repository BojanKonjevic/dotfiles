{...}: {
  flake.nixosModules.core = {
    pkgs,
    userConfig,
    inputs,
    ...
  }: {
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
    hardware.enableAllFirmware = true;
    nixpkgs.config.allowUnfree = true;
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    nix.optimise.automatic = true;

    users.users.${userConfig.username} = {
      shell = pkgs.zsh;
      isNormalUser = true;
      description = userConfig.fullName;
      extraGroups = [
        "libvirtd"
        "networkmanager"
        "wheel"
        "audio"
        "input"
        "ydotool"
        "video"
      ];
    };
  };
}
