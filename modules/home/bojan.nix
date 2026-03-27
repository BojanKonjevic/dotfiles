{
  self,
  inputs,
  ...
}: let
  userConfig = import ../../user.nix;
  system = userConfig.system;
  pkgs = inputs.nixpkgs.legacyPackages.${system};
in {
  flake.homeConfigurations.${userConfig.username} = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {
      inherit inputs userConfig;
      quickshell = inputs.quickshell.packages.${system}.default;
    };
    modules =
      [
        self.homeModules.theme
      ]
      ++ (builtins.attrValues (builtins.removeAttrs self.homeModules ["theme"]))
      ++ [
        inputs.catppuccin.homeModules.catppuccin
        inputs.nixvim.homeModules.nixvim
        inputs.zen-browser.homeModules.default
        {
          home.username = userConfig.username;
          home.homeDirectory = userConfig.homeDirectory;
          home.stateVersion = userConfig.stateVersion;
          nixpkgs.config.allowUnfree = true;
          news.display = "silent";
          home.packages = with pkgs; [
            python3
            glow
            libnotify
            ripgrep
            fd
            duf
            gdu
            pinta
            localsend
            alsa-utils
            p7zip
            unzip
            dejsonlz4
            file-roller
            libreoffice
            pavucontrol
            tree
          ];
        }
      ];
  };
}
