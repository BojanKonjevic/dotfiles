{inputs, ...}: {
  imports = [
    ../../../modules/home/theme.nix
    ../../../modules/home/terminal.nix
    ../../../modules/home/ssh.nix
    ../../../modules/home/macos/ui.nix
    ../../../modules/home/weather.nix
    ../../../modules/home/macos/mic-toggle.nix
    ../../../modules/home/macos/terminal-aliases.nix
    ../../../modules/home/scripts.nix
    inputs.nixvim.homeModules.nixvim
    ../../../modules/home/nixvim
    ../../../modules/home/yazi.nix
  ];
}
