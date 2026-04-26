{
  inputs,
  config,
  ...
}: {
  flake.nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      ./configuration.nix
    ];
  };

  perSystem = {...}: {
    packages.iso = config.flake.nixosConfigurations.iso.config.system.build.isoImage;
  };
}
