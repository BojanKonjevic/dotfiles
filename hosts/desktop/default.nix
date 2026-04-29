{
  self,
  inputs,
  ...
}: let
  userConfig = (import ../../user.nix) // (import ./config.nix);
  bootstrapFiles = [
    "config.nix"
    "default.nix"
    "hardware.nix"
    "disko.nix"
  ];
  hostDir = ./.;
  extraModules =
    builtins.filter
    (f: builtins.pathExists f)
    (map
      (f: hostDir + "/${f}")
      (builtins.filter
        (f: !builtins.elem f bootstrapFiles)
        (builtins.attrNames (builtins.readDir hostDir))));
in {
  flake.nixosConfigurations.${userConfig.hostname} = inputs.nixpkgs.lib.nixosSystem {
    system = userConfig.system;
    specialArgs = {inherit inputs userConfig self;};
    modules =
      [
        ./hardware.nix
        ./disko.nix
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit inputs userConfig;
            quickshell = inputs.quickshell.packages.${userConfig.system}.default;
          };
          home-manager.users.${userConfig.username} = {
            inputs,
            userConfig,
            ...
          }: {
            imports = [
              inputs.catppuccin.homeModules.catppuccin

              # ── HM Profiles ──────────────────────────────────────────────
              ../../profiles/home/base.nix
              ../../profiles/home/desktop-env.nix
              ../../profiles/home/programming.nix
              ../../profiles/home/media.nix
              ../../profiles/home/misc.nix
            ];
            home.username = userConfig.username;
            home.homeDirectory = userConfig.homeDirectory;
            home.stateVersion = userConfig.stateVersion;
            news.display = "silent";
          };
        }

        # ── Profiles ───────────────────────────────────────────────────────
        ../../profiles/system/base.nix
        ../../profiles/system/misc.nix
        ../../profiles/system/nvidia.nix
        #../../profiles/system/gaming.nix
      ]
      ++ extraModules;
  };
}
