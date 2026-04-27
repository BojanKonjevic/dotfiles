{pkgs, ...}: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
  };
  environment.sessionVariables.STEAM_FRAME_FORCE_CLOSE = "1";

  environment.systemPackages = with pkgs; [
    gamemode
    gamescope
    mangohud
    steam-run
  ];

  powerManagement.cpuFreqGovernor = "performance";
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
        desiredgov = "performance";
      };
    };
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
    "vm.dirty_writeback_centisecs" = 1500;
    "kernel.perf_event_paranoid" = 2;
  };
}
