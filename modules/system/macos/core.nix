{
  pkgs,
  userConfig,
  ...
}: {
  networking.hostName = userConfig.hostname;
  time.timeZone = userConfig.timezone;
  system.defaults.NSGlobalDomain.AppleLocale = userConfig.locale;
  system.defaults.NSGlobalDomain.AppleICUForce24HourTime = true;
  security.pam.enableSudoTouchIdAuth = true;
  nix = {
    enable = true;
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      trusted-users = [userConfig.username];
      substituters = [
        "https://cache.nixos.org"
        "https://bkonjevic.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "bkonjevic.cachix.org-1:WpjIBY5gJqM76A4oBSWNu8tt9z5vFbGstqQp9MlrTZw="
      ];
      download-buffer-size = 1073741824;
      max-jobs = "auto";
    };
    gc = {
      automatic = true;
      interval = {
        Weekday = 7;
        Hour = 3;
        Minute = 0;
      };
      options = "--delete-older-than 14d";
    };
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };
  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
  environment.shells = [pkgs.zsh];
  environment.systemPackages = [pkgs.vim];
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 1000.0;
  };
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    ShowPathbar = true;
    FXPreferredViewStyle = "clmv";
    FXEnableExtensionChangeWarning = false;
    QuitMenuItem = true;
  };
  system.defaults.screencapture = {
    location = userConfig.screenshotsDir;
    type = "png";
    disable-shadow = true;
  };
  system.defaults.NSGlobalDomain = {
    AppleKeyboardUIMode = 3;
    ApplePressAndHoldEnabled = false;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
    NSNavPanelExpandedStateForSaveMode = true;
    NSTableViewDefaultSizeMode = 2;
  };
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };
  system.defaults.trackpad = {
    Clicking = true;
    TrackpadRightClick = true;
    TrackpadThreeFingerDrag = true;
  };
  system.defaults.universalaccess.reduceTransparency = false;

  # Never sleep when on AC power — display still turns off, no wake delay at desk
  system.activationScripts.power.text = ''
    pmset -c sleep 0
  '';

  # ── Keyboard Best Practices ────────────────────────────────────────────────
  # For 1:1 AeroSpace experience on the 60% + MacBook Air built-in keyboard:
  # System Settings → Keyboard → Modifier Keys → select each keyboard →
  #   swap Option (⌥) ↔ Command (⌘)
  # This makes the thumb-key next to spacebar = Option/AeroSpace on both keyboards.
  # ────────────────────────────────────────────────────────────────────────────

  system.defaults.loginwindow = {
    GuestEnabled = false;
    SHOWFULLNAME = true;
  };
  system.defaults.CustomMenuBar = [];
  system.stateVersion = 4;
}
