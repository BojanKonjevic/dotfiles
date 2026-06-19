{
  pkgs,
  userConfig,
  ...
}: {
  networking.hostName = userConfig.hostname;
  time.timeZone = userConfig.timezone;
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
        "https://bojan-dotfiles.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "bojan-dotfiles.cachix.org-1:35eXWoN9Ob91Tn6cEhgLJ+6a09KMnZfRzKHbkQrPOX0="
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
    autohide-delay = 999999;
    autohide-time-modifier = 0.0;
    mru-spaces = false;
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
    AppleInterfaceStyle = "Dark";
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
    NSAutomaticWindowAnimationsEnabled = false;
    NSWindowShouldDragOnGesture = true;
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

  # ── Keyboard Consistency (60% external + MacBook built-in) ─────────────────
  # Goal: Rfit modifier (⌥) is always the thumb key next to spacebar.
  #
  # Layouts before swapping:
  #
  #   60% (left of spacebar):      Ctrl  |  Win        |  Alt  |  ← thumb
  #   MacBook (left of spacebar):  Fn    |  Ctrl       |  ⌥    |  ⌘    ← thumb
  #
  #   60% key → macOS maps as:     Ctrl  →  Ctrl
  #                                Win   →  ⌘
  #                                Alt   →  ⌥   ← thumb, Rfit modifier
  #
  # Problem: on the MacBook built-in, the thumb key is ⌘, not ⌥.
  # Fix: swap ⌥ ↔ ⌘ for the internal keyboard only.
  #
  # After swapping:
  #
  #   60%:                        Ctrl  |  Win  (⌘)  |  Alt  (⌥)  |  ← thumb (⌥)
  #   MacBook built-in:           Fn    |  Ctrl       |  ⌘          |  ⌥     ← thumb (⌥)
  #
  #   Ctrl is corner on 60%, position 2 on MacBook — close enough.
  #   Win/⌘ is middle on both. Copy/paste muscle memory matches.
  #   Thumb = ⌥ = Rfit modifier on both keyboards. ✓
  #
  # System Settings → Keyboard → Modifier Keys → select "MacBook Air Keyboard" →
  #   swap Option (⌥) ↔ Command (⌘)
  # ────────────────────────────────────────────────────────────────────────────

  system.defaults.WindowManager = {
    EnableStandardClickToShowDesktop = false;
    StandardHideDesktopIcons = true;
    EnableTilingByEdgeDrag = false;
    EnableTopTilingByEdgeDrag = false;
    EnableTilingOptionAccelerator = false;
    EnableTiledWindowMargins = false;
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.Siri".StatusMenuVisible = false;
    "com.apple.assistant.support"."Assistant Enabled" = false;
    "com.apple.Siri".VoiceTriggerUserEnabled = false;
    "NSGlobalDomain".AppleLocale = userConfig.locale;
  };

  # Kill Spotlight completely — icon hidden, keyboard shortcuts disabled
  # Raycast replaces Cmd+Space, indexing stays on (Raycast and other apps need it)
  system.activationScripts.extraUser.text = ''
    defaults -currentHost write com.apple.Spotlight MenuItemHidden -int 1
    /usr/libexec/PlistBuddy -c "Set AppleSymbolicHotKeys:64:enabled false" \
      ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set AppleSymbolicHotKeys:65:enabled false" \
      ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null || true

    # Kill Mission Control gestures — 3-finger swipe up/down/spread
    defaults -currentHost write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0
    defaults -currentHost write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 0
    defaults -currentHost write com.apple.AppleMultitouchTrackpad TrackpadPinchGesture -int 0
  '';

  system.defaults.loginwindow = {
    GuestEnabled = false;
    SHOWFULLNAME = true;
  };
  system.stateVersion = userConfig.darwinSystemVersion;
}
