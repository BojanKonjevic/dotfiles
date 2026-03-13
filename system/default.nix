{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    gcc
    gnumake
    pkg-config
    zlib
    openssl
    openssl.dev
    libffi
    cargo
    python3
  ];
  imports = [
    ./system/hardware-configuration.nix
    ./system/audio.nix
    ./system/display.nix
    ./system/core.nix
  ];

  services.postgresql = {
    enable = true;
    ensureDatabases = [];
    ensureUsers = [
      {
        name = "bojan";
        ensureClauses.superuser = true;
        ensureClauses.createdb = true;
      }
    ];
  };
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.download-buffer-size = 134217728;
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;
  networking.hostName = "nixos";
  time.timeZone = "Europe/Belgrade";
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "25.11";
}
