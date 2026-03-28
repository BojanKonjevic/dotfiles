{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = {pkgs, ...}: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.alejandra.enable = true;

      settings.formatter.qmlformat = {
        command = "${pkgs.kdePackages.qtdeclarative}/bin/qmlformat";
        options = ["-i"];
        includes = ["*.qml"];
      };
    };
  };
}
