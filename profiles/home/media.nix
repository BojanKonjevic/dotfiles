{inputs, ...}: {
  imports = [
    inputs.zen-browser.homeModules.default
    ../../modules/home/zen-browser.nix
    ../../modules/home/qbittorrent.nix
    ../../modules/home/zathura.nix
    ../../modules/home/vesktop.nix
  ];
}
