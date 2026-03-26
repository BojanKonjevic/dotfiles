{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "power-menu" ''
      qs -c powermenu
    '')
  ];
}
