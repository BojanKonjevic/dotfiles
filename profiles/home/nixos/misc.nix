{pkgs, ...}: {
  home.packages = with pkgs; [
    localsend
    libreoffice
    gnome-calculator
    alsa-utils
    file-roller
    pavucontrol
    networkmanagerapplet
    pinta
    bruno
    tableplus
  ];
}
