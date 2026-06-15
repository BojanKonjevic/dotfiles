{
  pkgs,
  lib,
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
    ++ lib.optionals pkgs.stdenv.isDarwin [
      cliclick
      shottr
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      localsend
      libreoffice
      gnome-calculator
      alsa-utils
      file-roller
      pavucontrol
      networkmanagerapplet
      pinta
    ]
    ++ [(inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default)];
}
