{inputs, ...}: {
  flake.nixosModules.secrets = {
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
    age.secrets.user-password.file = "${self}/secrets/user-password.age";
    age.secrets.cachix-token = {
      file = "${self}/secrets/cachix-token.age";
      owner = userConfig.username;
      mode = "0400";
    };
    age.secrets.ssh-private-key = {
      file = "${self}/secrets/ssh-private-key.age";
      owner = userConfig.username;
      mode = "0600";
    };
  };
}
