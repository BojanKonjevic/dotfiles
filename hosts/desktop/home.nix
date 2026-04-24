{inputs, ...}: let
  userConfig = import ./config.nix;
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

      # ── Universal home modules ─────────────────────────────────────────────
      # theme.nix is first: it sets _module.args.theme consumed by everything else
      ../../modules/home/theme.nix
      ../../modules/home/terminal.nix
      ../../modules/home/ui.nix
      ../../modules/home/weather.nix
      ../../modules/home/mic-toggle.nix
      ../../modules/home/scripts.nix

      # ── Desktop profiles ───────────────────────────────────────────────────
      ../../profiles/home/desktop-env.nix
      ../../profiles/home/programming.nix
      ../../profiles/home/media.nix

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

      # ── Misc packages not yet sorted into a profile ────────────────────────
      {
        home.packages = with pkgs; [
          nvd
          cachix
          localsend
          libreoffice
          gnome-calculator
          alsa-utils
          p7zip
          unzip
          dejsonlz4
          file-roller
          pavucontrol
          networkmanagerapplet
          pinta
          inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
          glow
          ripgrep
          fd
          duf
          gdu
          tree
        ];
      }
    ];
  };
}
