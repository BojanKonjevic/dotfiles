{pkgs, ...}: {
  virtualisation.libvirtd.enable = false;
  programs.virt-manager.enable = false;
  virtualisation.spiceUSBRedirection.enable = true;
  environment.systemPackages = with pkgs; [
    qemu
  ];
}
