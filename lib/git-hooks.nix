{lib, ...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  in {
    pre-commit.settings.hooks =
      {
        alejandra.enable = true;
        shfmt = {
          enable = true;
          name = "shfmt";
          description = "Format shell scripts with shfmt";
          entry = "${pkgs.shfmt}/bin/shfmt -i 2 -w";
          files = "\\.sh$";
          language = "system";
          pass_filenames = true;
        };
      }
      // lib.optionalAttrs (!isDarwin) {
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
