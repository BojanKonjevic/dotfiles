{
  config,
  inputs,
  pkgs,
  ...
}: let
  nvidia-pkgs = import inputs.nixpkgs-nvidia {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in {
  # ── Use the NVIDIA hardware module from the pinned nixpkgs ──────────────
  imports = [
    "${inputs.nixpkgs-nvidia}/nixos/modules/hardware/video/nvidia.nix"
  ];
  disabledModules = ["hardware/video/nvidia.nix"];

  # ── Pin the kernel to the same pinned nixpkgs ───────────────────────────
  # This guarantees the old driver can build without kernel API mismatches.
  boot.kernelPackages = nvidia-pkgs.linuxPackages;

  # ── NVIDIA environment and driver settings ──────────────────────────────
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
