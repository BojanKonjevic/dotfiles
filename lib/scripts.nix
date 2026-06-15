{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    agenix = inputs.agenix.packages.${system}.default;
  in {
    apps.bootstrap-nixos = {
      meta.description = "Bootstrap a new NixOS machine from dotfiles";
      type = "app";
      program = toString (
        pkgs.writeShellScript "bootstrap-nixos" ''
          export PATH="${pkgs.git}/bin:${pkgs.home-manager}/bin:${pkgs.sbctl}/bin:${pkgs.mkpasswd}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${./scripts/bootstrap-nixos.sh} "$@"
        ''
      );
    };
    apps.bootstrap-macos = {
      meta.description = "Bootstrap a new macOS machine from dotfiles";
      type = "app";
      program = toString (
        pkgs.writeShellScript "bootstrap-macos" ''
          export PATH="${pkgs.git}/bin:${pkgs.nix}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${./scripts/bootstrap-macos.sh} "$@"
        ''
      );
    };
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
