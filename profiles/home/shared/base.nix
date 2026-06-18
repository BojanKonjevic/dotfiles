{inputs, ...}: {
  imports = [
    ../../../modules/home/shared/theme.nix
    ../../../modules/home/shared/terminal.nix
    ../../../modules/home/shared/ssh.nix
    ../../../modules/home/shared/weather.nix
    ../../../modules/home/shared/scripts.nix
    inputs.nixvim.homeModules.nixvim
    ../../../modules/home/shared/nixvim
    ../../../modules/home/shared/yazi.nix
  ];
}
