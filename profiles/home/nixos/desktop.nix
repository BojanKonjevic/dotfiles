{lib, ...}: {
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
  programs.ssh.settings = {
    "home" = {
      Hostname = "desktop.tail5d8060.ts.net";
      User = "bojan";
      Port = 22;
      StrictHostKeyChecking = "accept-new";
      ServerAliveInterval = 60;
      ServerAliveCountMax = 5;
    };
    "home-tailscale" = {
      Hostname = "100.95.213.119";
      User = "bojan";
      StrictHostKeyChecking = "accept-new";
    };
  };
}
