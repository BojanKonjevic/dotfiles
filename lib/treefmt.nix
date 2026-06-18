{lib, ...}: {
  perSystem = {pkgs, ...}: let
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  in {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.alejandra.enable = true;
      settings.formatter = lib.optionalAttrs (!isDarwin) {
        qmlformat = {
          command = "${pkgs.kdePackages.qtdeclarative}/bin/qmlformat";
          options = ["-i"];
          includes = ["*.qml"];
        };
      };
      programs.shfmt = {
        enable = true;
        indent_size = 2;
      };
    };
  };
}
