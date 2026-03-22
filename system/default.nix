{
  pkgs,
  userConfig,
  ...
}: {
  imports = [
    ./system/hardware-configuration.nix
    ./system/audio.nix
    ./system/display.nix
    ./system/core.nix
  ];

  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = userConfig.username;
        ensureClauses.superuser = true;
        ensureClauses.createdb = true;
      }
    ];
  };
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.download-buffer-size = 134217728;
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.tumbler.enable = true;
  networking.hostName = userConfig.hostname;
  time.timeZone = userConfig.timezone;
  i18n.defaultLocale = userConfig.locale;
  system.stateVersion = userConfig.stateVersion;
}
