{pkgs, ...}: let
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
    (mkPythonScript "ingest" ingestPython ../../../lib/scripts/ingest.py)
    (mkPythonScript "yttranscript" yttranscriptPython ../../../lib/scripts/yttranscript.py)
  ];
}
