{inputs, ...}: {
  flake.nixosModules.secrets = {
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
    age.secrets = lib.mkIf (!userConfig.bootstrapMode or false) {
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
    };
  };
}
