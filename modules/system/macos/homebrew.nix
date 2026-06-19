{userConfig, ...}: {
  nix-homebrew = {
    enable = true;
    user = userConfig.username;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    brews = ["mas"];
    casks = [];
    masApps = {};
  };
}
