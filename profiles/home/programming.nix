{pkgs, ...}: {
  home.packages = with pkgs; [
    docker
    python3
  ];
}
