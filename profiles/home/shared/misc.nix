{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs;
    [
      nvd
      cachix
      p7zip
      unzip
      dejsonlz4
      glow
      ripgrep
      fd
      duf
      gdu
      tree
    ]
    ++ [(inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default)];
}
