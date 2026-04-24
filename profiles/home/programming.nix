{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ../../modules/home/nixvim.nix
  ];

  home.packages = with pkgs; [
    python3
  ];
}
