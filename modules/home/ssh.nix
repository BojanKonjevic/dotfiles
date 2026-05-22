{pkgs, ...}: {
  home.packages = with pkgs; [
    mosh
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        extraOptions = {
          ServerAliveInterval = "60";
          ServerAliveCountMax = "3";
          SetEnv = "TERM=xterm-256color";
        };
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };

      # home machine
      "home" = {
        hostname = "bojandesktop.duckdns.org";
        user = "bojan";
        port = 22;
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          # Mosh handles keepalive itself, but SSH fallback still benefits from these
          ServerAliveInterval = "60";
          ServerAliveCountMax = "5";
          # Speed up reconnects
          ControlMaster = "auto";
          ControlPath = "~/.ssh/control-%C";
          ControlPersist = "10m";
        };
      };
    };
  };

  services.ssh-agent.enable = true;

  home.file.".ssh/id_ed25519.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8WKB45Qb5CqZPlE7LWKjkaCikJbjA87sVQwJWDTAB4 konjevicbojan1@gmail.com";
}
