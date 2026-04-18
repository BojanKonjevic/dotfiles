{...}: {
  perSystem = {pkgs, ...}: {
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
