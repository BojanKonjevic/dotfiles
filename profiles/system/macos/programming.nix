{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    python314
    uv
    ruff
    mypy
    just
    opencode
    pnpm
    nodejs
    docker-client
  ];

  services.redis = {
    enable = true;
    port = 6379;
  };
}
