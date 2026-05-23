{pkgs, ...}: {
  home.packages = with pkgs; [
    ttyd
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
        hostname = "desktop.tail5d8060.ts.net";
        user = "bojan";
        port = 22;
        extraOptions = {
          StrictHostKeyChecking = "no";
          ServerAliveInterval = "60";
          ServerAliveCountMax = "5";
        };
      };
      "home-tailscale" = {
        hostname = "100.95.213.119";
        user = "bojan";
        extraOptions = {
          StrictHostKeyChecking = "no";
        };
      };
    };
  };

  services.ssh-agent.enable = true;

  home.file.".ssh/id_ed25519.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8WKB45Qb5CqZPlE7LWKjkaCikJbjA87sVQwJWDTAB4 konjevicbojan1@gmail.com";
}
