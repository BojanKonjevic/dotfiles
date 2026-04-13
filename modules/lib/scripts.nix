{...}: {
  flake.homeModules.scripts = {pkgs, ...}: {
    home.packages = [
      (pkgs.stdenv.mkDerivation {
        name = "ingest";
        src = ./scripts/ingest.py;
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/bin
          cp $src $out/bin/ingest
          chmod +x $out/bin/ingest
          patchShebangs $out/bin/ingest
        '';
      })

      (pkgs.stdenv.mkDerivation {
        name = "yttranscript";
        src = ./scripts/yttranscript.py;
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/bin
          cp $src $out/bin/yttranscript
          chmod +x $out/bin/yttranscript
          patchShebangs $out/bin/yttranscript
        '';
      })

      (pkgs.writeShellScriptBin "pyproj" ''
        exec ${pkgs.bash}/bin/bash ${./scripts/new-python-project.sh} "$@"
      '')
    ];
  };
}
