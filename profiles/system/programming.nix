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
    pnpm
    nodejs
  ];

  virtualisation.docker.enable = true;
  programs.nix-ld.enable = true;
}
