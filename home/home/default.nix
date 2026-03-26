{
  pkgs,
  userConfig,
  ...
}: {
  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;
  home.stateVersion = userConfig.stateVersion;

  imports = [
    ./modules/quickshell.nix
    ./modules/theme.nix
    ./modules/ui.nix
    ./modules/waybar.nix
    ./modules/terminal.nix
    ./modules/nixvim.nix
    ./modules/hyprland.nix
    ./modules/hyprlock.nix
    ./modules/hypridle.nix
    ./modules/zen-browser.nix
    ./modules/vesktop.nix
    ./modules/setwall.nix
    ./modules/rofi.nix
    ./modules/powermenu.nix
    ./modules/clipboard.nix
    ./modules/swaync.nix
    ./modules/mic-toggle.nix
    ./modules/weather.nix
    ./modules/media.nix
    ./modules/qbittorrent.nix
    ./modules/zathura.nix
  ];

  home.packages = with pkgs; [
    python3
    glow
    libnotify
    ripgrep
    fd
    duf
    gdu
    pinta
    localsend
    alsa-utils
    p7zip
    unzip
    dejsonlz4
    file-roller
    libreoffice
    pavucontrol
  ];
  nixpkgs.config.allowUnfree = true;
  news.display = "silent";
}
