{...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    pre-commit.settings.hooks.alejandra.enable = true;

    devShells.default = pkgs.mkShell {
      shellHook = config.pre-commit.installationScript;
    };
  };
}
