{
  inputs,
  lib,
  userConfig,
  self,
  ...
}: {
  imports = [inputs.agenix.nixosModules.default];
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
    };
  };
  age.secrets = lib.mkIf (!userConfig.bootstrapMode) {
    cachix-token = {
      file = "${self}/secrets/cachix-token.age";
      owner = userConfig.username;
      mode = "0400";
    };
    ssh-private-key = {
      file = "${self}/secrets/ssh-private-key.age";
      owner = userConfig.username;
      mode = "0600";
    };
    pypi-key = {
      file = "${self}/secrets/pypi-key.age";
      owner = userConfig.username;
      mode = "0400";
    };
    restic-password = {
      file = "${self}/secrets/restic-password.age";
      owner = "root";
      mode = "0400";
    };
    restic-env = {
      file = "${self}/secrets/restic-env.age";
      owner = "root";
      mode = "0400";
    };
    duckdns-token = {
      file = "${self}/secrets/duckdns-token.age";
      owner = "root";
      mode = "0400";
    };
  };
  age.identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
}
