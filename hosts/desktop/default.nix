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
    "home.nix"
    "bootstrap-override.nix"
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

        # ── Profiles ───────────────────────────────────────────────────────
        ../../profiles/system/base.nix
        ../../profiles/system/misc.nix
        ../../profiles/system/nvidia.nix
      ]
      ++ extraModules;
  };
}
