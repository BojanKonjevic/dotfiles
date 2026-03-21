{
  pkgs,
  inputs,
  userConfig,
  ...
}: let
  nix-search =
    inputs.nix-search-tv.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;
  home.stateVersion = userConfig.stateVersion;

  imports = [
    ./modules/vesktop.nix
    ./modules/mic-toggle.nix
    ./modules/powermenu.nix
    ./modules/clipboard.nix
    ./modules/terminal.nix
    ./modules/nixvim.nix
    ./modules/hypridle.nix
    ./modules/hyprland.nix
    ./modules/hyprlock.nix
    ./modules/ui.nix
    ./modules/waybar.nix
    ./modules/swaync.nix
    ./modules/rofi.nix
    ./modules/zathura.nix
    ./modules/setwall.nix
    ./modules/zen-browser.nix
    ./modules/weather.nix
  ];

  home.packages = with pkgs; [
    python3
    ansifilter
    sox
    nh
    glow
    nwg-look
    swayimg
    libnotify
    nix-search
    speedtest-go
    eza
    ripgrep
    fd
    duf
    gdu
    mpv
    qbittorrent
    pinta
    grim
    slurp
    wl-clipboard
    cliphist
    nixd
    localsend
    bibata-cursors
    alsa-utils
    swww
    p7zip
    dejsonlz4
    file-roller
    xarchiver
    libreoffice
    pavucontrol
    networkmanagerapplet
    calcurse
    nerd-fonts.jetbrains-mono
    (catppuccin-gtk.override {
      accents = ["mauve"];
      variant = "mocha";
    })
  ];
  programs.zoxide.enable = true;
  programs.broot.enable = true;
  programs.bat.enable = true;
  programs.btop.enable = true;
  programs.cava.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user.name = userConfig.fullName;
      user.email = userConfig.email;
      init.defaultBranch = "main";
    };
  };
  nixpkgs.config.allowUnfree = true;
  news.display = "silent";
}
