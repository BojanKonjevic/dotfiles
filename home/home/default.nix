{
  pkgs,
  inputs,
  ...
}: let
  zen-browser =
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
  nix-search =
    inputs.nix-search-tv.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home.username = "bojan";
  home.homeDirectory = "/home/bojan";
  home.stateVersion = "25.11";

  imports = [
    ./modules/terminal.nix
    ./modules/nixvim.nix
    ./modules/hypridle.nix
    ./modules/hyprland.nix
    ./modules/hyprlock.nix
    ./modules/ui.nix
    ./modules/waybar.nix
    ./modules/swaync.nix
    ./modules/wofi.nix
    ./modules/zathura.nix
  ];

  home.packages = with pkgs; [
    glow
    nwg-look
    swayimg
    libnotify
    nix-search
    speedtest-go
    zen-browser
    eza
    thunar
    tumbler
    ripgrep
    fd
    fzf
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
    clippy
    bibata-cursors
    nerd-fonts.jetbrains-mono
    alsa-utils
    hyprpaper
    p7zip
    xarchiver
    pavucontrol
    nerdfetch
    networkmanagerapplet
    calcurse
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
