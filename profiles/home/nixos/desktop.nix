{...}: {
  imports = [
    ../../../modules/home/nixos/hypridle.nix
    ../../../modules/home/nixos/hyprland.nix
    ../../../modules/home/nixos/hyprlock.nix
    ../../../modules/home/nixos/quickshell
  ];
  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
    settings = {
      "preset" = 3;
      "toggle_hud" = "Shift_R+F12";
    };
  };
}
