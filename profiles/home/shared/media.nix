{inputs, ...}: {
  imports = [
    inputs.zen-browser.homeModules.default
    ../../../modules/home/shared/zen-browser.nix
    ../../../modules/home/shared/qbittorrent.nix
    ../../../modules/home/shared/vesktop.nix
    ../../../modules/home/shared/zathura.nix
  ];
}
