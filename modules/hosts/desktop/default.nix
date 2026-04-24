{
  self,
  inputs,
  ...
}: let
  userConfig = import ../../../user.nix;
in {
  flake.nixosConfigurations.${userConfig.hostname} = inputs.nixpkgs.lib.nixosSystem {
    system = userConfig.system;
    specialArgs = {inherit inputs userConfig self;};
    modules =
      (builtins.attrValues self.nixosModules)
      ++ [
        ./hardware.nix
        ./disko.nix
        ./impermanence.nix
        ./wipe-root.nix
        inputs.disko.nixosModules.disko
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.impermanence.nixosModules.impermanence
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
