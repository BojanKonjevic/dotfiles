{...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    pre-commit.settings.hooks = {
      alejandra.enable = true;
      qmlformat = {
        enable = true;
        name = "qmlformat";
        description = "Format QML files with qmlformat";
        entry = "${pkgs.kdePackages.qtdeclarative}/bin/qmlformat -i";
        files = "\\.qml$";
        language = "system";
        pass_filenames = true;
      };
    };

    devShells.default = pkgs.mkShell {
      shellHook = config.pre-commit.installationScript;
    };
  };
}
