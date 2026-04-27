{
  lib,
  userConfig,
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    restic
  ];

  services.restic.backups.daily = lib.mkIf (!userConfig.bootstrapMode) {
    initialize = true;
    repository = "b2:bojan-backup";
    passwordFile = config.age.secrets.restic-password.path;
    environmentFile = config.age.secrets.restic-env.path;

    paths = [
      "/home/${userConfig.username}"
      "/persist"
    ];

    exclude = [
      "/home/${userConfig.username}/dotfiles"
      "/home/${userConfig.username}/projects"
      "/home/${userConfig.username}/Downloads"
      "/home/${userConfig.username}/.cache"
      "/home/${userConfig.username}/.nix-defexpr"
      "/home/${userConfig.username}/.nix-profile"
      "/home/${userConfig.username}/.local/state/nix"
      "/home/${userConfig.username}/.zcompdump"
    ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };

    pruneOpts = [
      "--keep-daily 30"
      "--keep-weekly 24"
      "--keep-monthly 24"
    ];
  };
}
