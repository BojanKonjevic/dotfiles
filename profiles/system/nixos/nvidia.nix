{
  config,
  inputs,
  userConfig,
  ...
}: let
  system = userConfig.system;
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  nvidia-pkgs = import inputs.nixpkgs-nvidia {
    inherit system;
    config.allowUnfree = true;
  };
in {
  imports = [
    "${inputs.nixpkgs-nvidia}/nixos/modules/hardware/video/nvidia.nix"
  ];
  disabledModules = ["hardware/video/nvidia.nix"];

  boot.kernelPackages = nvidia-pkgs.linuxPackages;

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
  boot.kernelParams = ["nvidia-drm.modeset=1"];
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = (nvidia-pkgs.linuxKernel.packagesFor config.boot.kernelPackages.kernel).nvidiaPackages.production;
  };
}
