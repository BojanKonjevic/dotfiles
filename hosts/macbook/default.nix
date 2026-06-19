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
              inputs.mac-app-util.homeManagerModules.default

              # ── HM Profiles ──────────────────────────────────────────────
              ../../profiles/home/macos/base.nix
              ../../profiles/home/macos/desktop.nix
              ../../profiles/home/macos/misc.nix
              ../../profiles/home/shared/base.nix
              ../../profiles/home/shared/media.nix
              ../../profiles/home/shared/misc.nix
            ];
            home.username = userConfig.username;
            home.homeDirectory = lib.mkForce userConfig.homeDirectory;
            home.stateVersion = userConfig.stateVersion;
            news.display = "silent";
          };
        }

        # ── System Profiles ─────────────────────────────────────────────────
        ../../profiles/system/macos/base.nix
        ../../profiles/system/macos/desktop.nix
        ../../profiles/system/macos/media.nix
        ../../profiles/system/macos/misc.nix
        ../../profiles/system/shared/programming.nix
        #../../profiles/system/macos/gaming.nix
      ]
      ++ extraModules;
  };
}
