{...}: {
  perSystem = {pkgs, ...}: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.alejandra.enable = true;
      settings.formatter.qmlformat = {
        command = "${pkgs.kdePackages.qtdeclarative}/bin/qmlformat";
        options = ["-i"];
        includes = ["*.qml"];
      };
      programs.shfmt = {
        enable = true;
        indent_size = 2;
      };
    };
  };
}
