{...}: {
  flake.nixosModules.display = {
    config,
    inputs,
    pkgs,
    userConfig,
    ...
  }: let
    nvidia-pkgs = import inputs.nixpkgs-nvidia {
      system = pkgs.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  in {
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
      layout = userConfig.kbLayout;
      variant = "";
    };
    services.xserver.videoDrivers = ["nvidia"];
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = (nvidia-pkgs.linuxKernel.packagesFor config.boot.kernelPackages.kernel).nvidiaPackages.production;
    };
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    boot.kernelParams = ["nvidia-drm.modeset=1"];
  };
}
