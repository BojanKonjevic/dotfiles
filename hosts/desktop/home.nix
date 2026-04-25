{inputs, ...}: let
  userConfig = (import ../../user.nix) // (import ./config.nix);
  system = userConfig.system;
  pkgs = inputs.nixpkgs.legacyPackages.${system};
in {
  flake.homeConfigurations.${userConfig.username} = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {
      inherit inputs userConfig;
      quickshell = inputs.quickshell.packages.${system}.default;
    };
    modules = [
      inputs.catppuccin.homeModules.catppuccin

      # ── Profiles ──────────────────────────────────────────────────────────
      ../../profiles/home/base.nix
      ../../profiles/home/desktop-env.nix
      ../../profiles/home/programming.nix
      ../../profiles/home/media.nix
      ../../profiles/home/misc.nix

      # ── Base HM config ─────────────────────────────────────────────────────
      {
        home.username = userConfig.username;
        home.homeDirectory = userConfig.homeDirectory;
        home.stateVersion = userConfig.stateVersion;
        nix.package = pkgs.nix;
        nix.settings.warn-dirty = false;
        nixpkgs.config.allowUnfree = true;
        news.display = "silent";
      }
    ];
  };
}
