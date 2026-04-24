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
}
