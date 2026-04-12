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
        inputs.lanzaboote.nixosModules.lanzaboote
      ];
  };
}
