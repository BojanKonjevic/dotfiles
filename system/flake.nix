{
  description = "NixOS system flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    userConfig = import ../user.nix;
    system = userConfig.system;
  in {
    nixosConfigurations.${userConfig.hostname} = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs userConfig;
      };
      modules = [
        ./default.nix
      ];
    };
  };
}
