{
  pkgs,
  lib,
  ...
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
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
      ++ lib.optionals (!isDarwin) [docker];
  }
  // lib.optionalAttrs (!isDarwin) {
    services.redis.servers."" = {
      enable = true;
      port = 6379;
    };
    virtualisation.docker.enable = true;
    programs.nix-ld.enable = true;
  }
  // lib.optionalAttrs isDarwin {
    homebrew.casks = ["bruno" "orbstack" "tableplus"];
  }
