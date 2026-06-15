{
  inputs,
  pkgs,
  lib,
  userConfig,
  ...
}: let
  isDarwin = userConfig.system == "aarch64-darwin";
in {
  imports =
    [
      ../../modules/home/shared/theme.nix
      ../../modules/home/shared/terminal.nix
      ../../modules/home/shared/ssh.nix
      ../../modules/home/shared/weather.nix
      ../../modules/home/shared/scripts.nix
      inputs.nixvim.homeModules.nixvim
      ../../modules/home/shared/nixvim
      ../../modules/home/shared/yazi.nix
    ]
    ++ lib.optionals isDarwin [
      ../../modules/home/macos/ui.nix
      ../../modules/home/macos/mic-toggle.nix
      ../../modules/home/macos/terminal-aliases.nix
    ]
    ++ lib.optionals (!isDarwin) [
      ../../modules/home/nixos/ui.nix
      ../../modules/home/nixos/mic-toggle.nix
      ../../modules/home/nixos/terminal-aliases.nix
    ];
}
