{
  inputs,
  userConfig,
  ...
}: {
  imports = [
    inputs.catppuccin.homeModules.catppuccin

    # ── Profiles ──────────────────────────────────────────────────────────
    ../../profiles/home/base.nix
    ../../profiles/home/desktop-env.nix
    ../../profiles/home/programming.nix
    ../../profiles/home/media.nix
    ../../profiles/home/misc.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;
  home.stateVersion = userConfig.stateVersion;
  news.display = "silent";
}
