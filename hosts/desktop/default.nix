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

        # ── Universal system modules ───────────────────────────────────────
        ../../modules/system/core.nix
        ../../modules/system/audio.nix
        ../../modules/system/desktop.nix
        ../../modules/system/display.nix
        ../../modules/system/entry.nix
        ../../modules/system/lanzaboote.nix
        ../../modules/system/secrets.nix
        ../../modules/system/postgres.nix

        # ── Desktop-specific profiles ──────────────────────────────────────
        ../../profiles/system/nvidia.nix
        # DISABLED ../../profiles/system/virtualisation.nix
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
