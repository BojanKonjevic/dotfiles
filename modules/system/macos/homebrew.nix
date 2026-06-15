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
      "colima"
    ];
    casks = [
      "aerospace"
      "libreoffice"
      "localsend"
      "raycast"
      "obsidian"
      "spotify"
      "telegram"
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
