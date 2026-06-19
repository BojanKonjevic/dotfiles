{
  inputs,
  lib,
  userConfig,
  self,
  ...
}: {
  imports = [inputs.agenix.darwinModules.default];
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
  };
  age.identityPaths = ["/Users/${userConfig.username}/.ssh/id_ed25519"];
}
