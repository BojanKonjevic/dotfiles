{
  pkgs,
  config,
  userConfig,
  ...
}: {
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };
  networking.firewall.allowedTCPPorts = [22];
  users.users.${userConfig.username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8WKB45Qb5CqZPlE7LWKjkaCikJbjA87sVQwJWDTAB4 konjevicbojan1@gmail.com"
  ];
  environment.systemPackages = with pkgs; [mosh tailscale];
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    extraUpFlags = ["--ssh"];
    authKeyFile = config.age.secrets.tailscale.path;
  };
  systemd.services.tailscale-funnel = {
    description = "Tailscale Funnel for ttyd";
    after = ["tailscaled.service" "tailscaled-autoconnect.service" "ttyd.service"];
    wants = ["tailscaled.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale funnel --bg 7681";
    };
  };
  systemd.services.ttyd = {
    description = "ttyd web terminal";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.writeShellScriptBin "ttyd-start" ''
        exec ${pkgs.ttyd}/bin/ttyd -p 7681 -W \
          -t rendererType=webgl \
          -t lineHeight=1.2 \
          -t cursorStyle=block \
          -t cursorBlink=false \
          -t scrollback=5000 \
          -t bellStyle=none \
          -t 'theme={"background":"#1e1e2e","foreground":"#cdd6f4","cursor":"#cba6f7","black":"#45475a","red":"#f38ba8","green":"#a6e3a1","yellow":"#f9e2af","blue":"#89b4fa","magenta":"#cba6f7","cyan":"#94e2d5","white":"#bac2de","brightBlack":"#585b70","brightRed":"#f38ba8","brightGreen":"#a6e3a1","brightYellow":"#f9e2af","brightBlue":"#89b4fa","brightMagenta":"#cba6f7","brightCyan":"#94e2d5","brightWhite":"#cdd6f4"}' \
          -c "$(cat ${config.age.secrets.ttyd.path})" \
          ${pkgs.zsh}/bin/zsh
      ''}/bin/ttyd-start";
      Restart = "always";
      User = userConfig.username;
    };
  };
}
