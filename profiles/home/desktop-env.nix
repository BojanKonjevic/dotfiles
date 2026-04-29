{...}: {
  imports = [
    ../../modules/home/hypridle.nix
    ../../modules/home/hyprland.nix
    ../../modules/home/hyprlock.nix
    ../../modules/home/quickshell
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
