{pkgs, ...}: {
  home.packages = with pkgs; [
    ttyd
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        SetEnv.TERM = "xterm-256color";
      };

      "github.com" = {
        Hostname = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      "home" = {
        Hostname = "desktop.tail5d8060.ts.net";
        User = "bojan";
        Port = 22;
        StrictHostKeyChecking = "no";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 5;
      };
      "home-tailscale" = {
        Hostname = "100.95.213.119";
        User = "bojan";
        StrictHostKeyChecking = "no";
      };
    };
  };

  services.ssh-agent.enable = !pkgs.stdenv.hostPlatform.isDarwin;

  home.file.".ssh/id_ed25519.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8WKB45Qb5CqZPlE7LWKjkaCikJbjA87sVQwJWDTAB4 konjevicbojan1@gmail.com";
}
