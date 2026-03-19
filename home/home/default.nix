{
  pkgs,
  inputs,
  ...
}: let
  nix-search =
    inputs.nix-search-tv.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home.username = "bojan";
  home.homeDirectory = "/home/bojan";
  home.stateVersion = "25.11";

  imports = [
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
    vesktop
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
  programs.fzf.enable = true;
  programs.broot.enable = true;
  programs.bat.enable = true;
  programs.btop.enable = true;
  programs.cava.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user.name = "BojanKonjevic";
      user.email = "konjevicbojan1@gmail.com";
      init.defaultBranch = "main";
    };
  };
  nixpkgs.config.allowUnfree = true;
  news.display = "silent";
}
