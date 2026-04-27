{
  pkgs,
  userConfig,
  ...
}: {
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };
  services.xserver.xkb = {
    layout = userConfig.kbLayout;
    variant = "";
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages32 = with pkgs.pkgsi686Linux; [
      libva
      libva-vdpau-driver
    ];
  };
}
