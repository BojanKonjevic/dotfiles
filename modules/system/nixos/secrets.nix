{
  inputs,
  lib,
  userConfig,
  self,
  ...
}: {
  imports = [inputs.agenix.nixosModules.default];
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
    tailscale = {
      file = "${self}/secrets/tailscale.age";
      owner = "root";
      mode = "0400";
    };
    ttyd = {
      file = "${self}/secrets/ttyd.age";
      owner = userConfig.username;
      mode = "0400";
    };
  };
  age.identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
}
