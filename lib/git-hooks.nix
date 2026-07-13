{...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    pre-commit.settings.hooks.treefmt = {
      enable = true;
      package = config.treefmt.build.wrapper;
    };

    devShells.default = pkgs.mkShell {
      shellHook = config.pre-commit.installationScript;
    };
  };
}
