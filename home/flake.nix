{
  description = "Home Manager config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nix-search-tv.url = "github:3timeslazy/nix-search-tv";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    userConfig = import ../user.nix;
    system = userConfig.system;
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    homeConfigurations.${userConfig.username} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs userConfig;
        quickshell = inputs.quickshell.packages.${system}.default;
      };
      modules = [
        inputs.catppuccin.homeModules.catppuccin
        inputs.nixvim.homeModules.nixvim
        inputs.zen-browser.homeModules.default
        ./home/default.nix
      ];
    };
  };
}
