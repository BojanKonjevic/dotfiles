{pkgs, ...}: {
  home.packages = with pkgs; [
    cliclick
    shottr
  ];
}
