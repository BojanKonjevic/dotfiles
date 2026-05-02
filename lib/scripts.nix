{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    agenix = inputs.agenix.packages.${system}.default;
  in {
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
    apps.new-python-project = inputs.new-python-project.apps.${system}.default;
    apps.post-install = {
      meta.description = "Post-install setup for a freshly bootstrapped system";
      type = "app";
      program = toString (
        pkgs.writeShellScript "post-install" ''
          export PATH="${pkgs.git}/bin:${agenix}/bin:${pkgs.neovim}/bin:${pkgs.nh}/bin:${pkgs.sbctl}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${./scripts/post-install.sh} "$@"
        ''
      );
    };
  };
}
