{...}: {
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    brews = [
      "mas"
    ];
    casks = [
      "aerospace"
      "ghostty"
      "raycast"
      "obsidian"
      "spotify"
      "telegram"
      "discord"
      "visual-studio-code"
      "qlmarkdown"
      "quicklook-json"
      "qlvideo"
      "the-unarchiver"
      "iina"
    ];
    masApps = {
      "WireGuard" = 1451685025;
    };
  };
}
