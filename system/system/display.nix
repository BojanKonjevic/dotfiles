{pkgs, userConfig, ...}: {
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
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
    layout = "us";
    variant = "";
  };
  services.xserver.videoDrivers = ["nvidia"];
  services.getty.autologinUser = userConfig.username;
  environment.loginShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      exec start-hyprland
    fi
  '';
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];
}
