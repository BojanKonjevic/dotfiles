{...}: {
  flake.nixosModules.postgres = {userConfig, ...}: {
    services.postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = userConfig.username;
          ensureClauses.superuser = true;
          ensureClauses.createdb = true;
        }
      ];
    };
  };
}
