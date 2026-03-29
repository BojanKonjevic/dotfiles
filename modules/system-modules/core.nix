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
    networking.hostName = userConfig.hostname;
    time.timeZone = userConfig.timezone;
    i18n.defaultLocale = userConfig.locale;
    system.stateVersion = userConfig.stateVersion;
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.settings.download-buffer-size = 134217728;
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
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
      initialPassword = "nixos";
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
