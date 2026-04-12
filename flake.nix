{
  description = "NixOS + Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-nvidia.url = "github:NixOS/nixpkgs/46db2e09e1d3f113a13c0d7b81e2f221c63b8ce9"; # pinned for pascal
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree = {
      url = "github:vic/import-tree";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    import-tree,
    treefmt-nix,
    ...
  }: let
    userConfig = import ./user.nix;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports =
        [
          ./modules/hosts/${userConfig.hostname}/default.nix
          treefmt-nix.flakeModule
          inputs.git-hooks.flakeModule
        ]
        ++ (import-tree ./modules/system-modules).imports
        ++ (import-tree ./modules/home-modules).imports
        ++ (import-tree ./modules/home).imports
        ++ (import-tree ./modules/lib).imports;
      systems = [userConfig.system];
    };
}
