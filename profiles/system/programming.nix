{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    docker
    python314
    uv
    ruff
    mypy
    just
    redis
    opencode
  ];

  virtualisation.docker.enable = true;
  programs.nix-ld.enable = true;
  programs.npm.enable = true;
}
