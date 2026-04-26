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
      PasswordAuthentication = false;
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
  };
}
