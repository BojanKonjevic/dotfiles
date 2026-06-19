{
  lib,
  userConfig,
  inputs,
  ...
}: let
  pkgs = inputs.nixpkgs.legacyPackages.${userConfig.system};
  isDarwin = userConfig.system == "aarch64-darwin";
in
  {
    environment.systemPackages = with pkgs;
      [
        python314
        uv
        ruff
        mypy
        just
        opencode
        pnpm
        nodejs
      ]
      ++ lib.optionals isDarwin [docker-client]
      ++ lib.optionals (!isDarwin) [bruno docker];
    services.redis.servers."" = lib.mkIf (!isDarwin) {
      enable = true;
      port = 6379;
    };
  }
  // lib.optionalAttrs (!isDarwin) {
    virtualisation.docker.enable = true;
    programs.nix-ld.enable = true;
  }
  // lib.optionalAttrs isDarwin {
    homebrew.casks = ["bruno" "orbstack"];
  }
