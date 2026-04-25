{...}: {
  perSystem = {pkgs, ...}: {
    apps.bootstrap = {
      meta.description = "Bootstrap a new NixOS machine from dotfiles";
      type = "app";
      program = toString (
        pkgs.writeShellScript "bootstrap" ''
          export PATH="${pkgs.git}/bin:${pkgs.home-manager}/bin:${pkgs.sbctl}/bin:${pkgs.mkpasswd}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${./scripts/bootstrap.sh} "$@"
        ''
      );
    };
    apps.new-python-project = {
      meta.description = "Creates a new python project from template";
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
