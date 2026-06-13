{inputs, ...}: {
  imports = [
    ../../../modules/home/theme.nix
    ../../../modules/home/terminal.nix
    ../../../modules/home/ssh.nix
    ../../../modules/home/nixos/ui.nix
    ../../../modules/home/weather.nix
    ../../../modules/home/nixos/mic-toggle.nix
    ../../../modules/home/nixos/terminal-aliases.nix
    ../../../modules/home/scripts.nix
    inputs.nixvim.homeModules.nixvim
    ../../../modules/home/nixvim
    ../../../modules/home/yazi.nix
  ];
}
