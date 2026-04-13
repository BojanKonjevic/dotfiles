{...}: {
  flake.homeModules.scripts = {pkgs, ...}: {
    home.packages = [
      (pkgs.stdenv.mkDerivation {
        name = "ingest";
        src = ../lib/scripts/ingest.py;
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
        src = ../lib/scripts/yttranscript.py;
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/bin
          cp $src $out/bin/yttranscript
          chmod +x $out/bin/yttranscript
          patchShebangs $out/bin/yttranscript
        '';
      })

      (pkgs.writeShellScriptBin "pyproj" ''
        exec ${pkgs.bash}/bin/bash ${../lib/scripts/new-python-project.sh} "$@"
      '')
    ];
  };
}
