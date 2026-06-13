{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs;
    [
      nvd
      cachix
      localsend
      libreoffice
      gnome-calculator
      alsa-utils
      p7zip
      unzip
      dejsonlz4
      file-roller
      pavucontrol
      networkmanagerapplet
      pinta
      glow
      ripgrep
      fd
      duf
      gdu
      tree
    ]
    ++ [(inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default)];
}
