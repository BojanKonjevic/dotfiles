{
  pkgs,
  config,
  userConfig,
  ...
}: {
  services.openssh = {
    enable = true;
    # persist the host key across reboots
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

  networking.firewall = {
    allowedTCPPorts = [22];
    allowedUDPPortRanges = [
      {
        from = 60000;
        to = 61000;
      }
    ]; # mosh
  };

  users.users.${userConfig.username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8WKB45Qb5CqZPlE7LWKjkaCikJbjA87sVQwJWDTAB4 konjevicbojan1@gmail.com"
  ];
  environment.systemPackages = with pkgs; [mosh];
  networking.interfaces.enp6s0.ipv4.addresses = [
    {
      address = "192.168.1.2";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.1.1";
  services.duckdns = {
    enable = true;
    domains = ["bojandesktop"];
    tokenFile = config.age.secrets.duckdns-token.path;
  };
}
