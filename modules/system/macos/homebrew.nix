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
      "acsandmann/tap/rift"
    ];
    casks = [
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
    };
  };
}
