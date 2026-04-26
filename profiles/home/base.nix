{inputs, ...}: {
  imports = [
    ../../modules/home/theme.nix
    ../../modules/home/terminal.nix
    ../../modules/home/ui.nix
    ../../modules/home/weather.nix
    ../../modules/home/mic-toggle.nix
    ../../modules/home/scripts.nix
    inputs.nixvim.homeModules.nixvim
    ../../modules/home/nixvim.nix
    ../../modules/home/yazi.nix
  ];
}
