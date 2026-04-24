{pkgs, ...}: {
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.tumbler.enable = true;
}
