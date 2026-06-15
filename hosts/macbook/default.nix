{
  self,
  inputs,
  ...
}: let
  userConfig = (import ../../user.nix) // (import ./config.nix);
  bootstrapFiles = [
    "config.nix"
    "default.nix"
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
  flake.darwinConfigurations.${userConfig.hostname} = inputs.nix-darwin.lib.darwinSystem {
    system = userConfig.system;
    specialArgs = {inherit inputs userConfig self;};
    modules =
      [
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {inherit inputs userConfig;};
          home-manager.users.${userConfig.username} = {
            inputs,
            lib,
            userConfig,
            ...
          }: {
            imports = [
              inputs.catppuccin.homeModules.catppuccin

              # ── HM Profiles ──────────────────────────────────────────────
              ../../profiles/home/base.nix
              ../../profiles/home/desktop.nix
              ../../profiles/home/media.nix
              ../../profiles/home/misc.nix
            ];
            home.username = userConfig.username;
            home.homeDirectory = lib.mkForce userConfig.homeDirectory;
            home.stateVersion = userConfig.stateVersion;
            news.display = "silent";
          };
        }

        # ── System Profiles ─────────────────────────────────────────────────
        ../../profiles/system/base.nix
        ../../profiles/system/programming.nix
      ]
      ++ extraModules;
  };
}
