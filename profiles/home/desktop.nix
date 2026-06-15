{
  pkgs,
  lib,
  userConfig,
  ...
}: let
  isDarwin = userConfig.system == "aarch64-darwin";
in
  {
    imports =
      lib.optionals isDarwin [
        ../../modules/home/macos/aerospace.nix
        ../../modules/home/macos/raycast
        ../../modules/home/macos/mic-status-bar
        ../../modules/home/macos/cursor-warp
      ]
      ++ lib.optionals (!isDarwin) [
        ../../modules/home/nixos/hypridle.nix
        ../../modules/home/nixos/hyprland.nix
        ../../modules/home/nixos/hyprlock.nix
        ../../modules/home/nixos/quickshell
      ];
  }
  // lib.optionalAttrs (!isDarwin) {
    programs.mangohud = {
      enable = true;
      enableSessionWide = true;
      settings = {
        "preset" = 3;
        "toggle_hud" = "Shift_R+F12";
      };
    };
  }
