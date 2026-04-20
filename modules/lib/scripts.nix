{...}: {
  perSystem = {pkgs, ...}: {
    apps.bootstrap = {
      type = "app";
      program = toString (
        pkgs.writeShellScript "bootstrap" ''
          export PATH="${pkgs.git}/bin:${pkgs.home-manager}/bin:${pkgs.sbctl}/bin:${pkgs.mkpasswd}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${./scripts/bootstrap.sh} "$@"
        ''
      );
    };
    apps.new-python-project = {
      type = "app";
      program = toString (
        pkgs.writeShellScript "new-python-project" ''
          export PATH="${pkgs.uv}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${./scripts/new-python-project.sh} "$@"
        ''
      );
    };
  };

  flake.homeModules.scripts = {pkgs, ...}: let
    ingestPython = pkgs.python3.withPackages (ps: [ps.gitingest]);
    yttranscriptPython = pkgs.python3.withPackages (ps: [ps.youtube-transcript-api]);
    mkPythonScript = name: python: src:
      pkgs.writeTextFile {
        inherit name;
        destination = "/bin/${name}";
        executable = true;
        text = ''
          #!${python}/bin/python3
          ${builtins.readFile src}
        '';
      };
  in {
    home.packages = [
      pkgs.gitingest
      pkgs.wl-clipboard
      (mkPythonScript "ingest" ingestPython ./scripts/ingest.py)
      (mkPythonScript "yttranscript" yttranscriptPython ./scripts/yttranscript.py)
      (pkgs.writeShellScriptBin "pyproj" ''
        export PATH="${pkgs.uv}/bin:$PATH"
        exec ${pkgs.bash}/bin/bash ${./scripts/new-python-project.sh} "$@"
      '')
    ];
  };
}
