{
  self,
  inputs,
  ...
}: let
  userConfig = import ./config.nix;
in {
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs userConfig self;};
    modules =
      [
        ./hardware.nix
        ./disko.nix
        ./impermanence.nix
        ./wipe-root.nix
        inputs.disko.nixosModules.disko
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.impermanence.nixosModules.impermanence

        # ── Profiles ───────────────────────────────────────────────────────
        ../../profiles/system/base.nix
        ../../profiles/system/misc.nix
        ../../profiles/system/nvidia.nix
        # ../../profiles/system/virtualisation.nix
      ]
      ++ (
        let
          p = ./bootstrap-override.nix;
        in
          if builtins.pathExists p
          then [p]
          else []
      );
  };
}
