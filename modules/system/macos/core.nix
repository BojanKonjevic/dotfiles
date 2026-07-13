{
  pkgs,
  userConfig,
  lib,
  ...
}: {
  system.primaryUser = userConfig.username;
  networking.hostName = userConfig.hostname;
  time.timeZone = userConfig.timezone;
  documentation = {
    enable = false;
    doc.enable = false;
    man.enable = false;
    info.enable = false;
  };
  security.pam.services.sudo_local.touchIdAuth = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [];

  programs.zsh.enable = true;
  environment.shells = [pkgs.zsh];

  system.defaults = {
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
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

      AppleEnableSwipeNavigateWithScrolls = true;
      "com.apple.springing.enabled" = true;
      "com.apple.springing.delay" = 0.5;
      "com.apple.trackpad.forceClick" = true;
    };

    dock = {
      autohide = true;
      autohide-delay = 999999.0;
      autohide-time-modifier = 0.0;
      mru-spaces = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowPathbar = true;
      FXPreferredViewStyle = "icnv";
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      NewWindowTarget = "Home";
    };

    screencapture = {
      location = userConfig.screenshotsDir;
      type = "png";
      disable-shadow = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
      TrackpadThreeFingerTapGesture = 0;
    };

    menuExtraClock = {
      ShowAMPM = true;
      ShowDayOfWeek = true;
      ShowDate = 0;
      Show24Hour = true;
      ShowSeconds = false;
    };

    WindowManager = {
      EnableStandardClickToShowDesktop = false;
      StandardHideDesktopIcons = true;
      EnableTilingByEdgeDrag = false;
      EnableTopTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
      EnableTiledWindowMargins = false;
      GloballyEnabled = false;
      AutoHide = false;
      AppWindowGroupingBehavior = true;
      HideDesktop = true;
      StandardHideWidgets = false;
      StageManagerHideWidgets = false;
    };

    loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = true;
    };

    # Settings without dedicated nix-darwin modules
    CustomUserPreferences = {
      "com.apple.Siri".StatusMenuVisible = false;
      "com.apple.assistant.support"."Assistant Enabled" = false;
      "com.apple.Siri".VoiceTriggerUserEnabled = false;
      "NSGlobalDomain".AppleLocale = userConfig.locale;
      "NSGlobalDomain".AppleMiniaturizeOnDoubleClick = false;
      "NSGlobalDomain"."com.apple.sound.beep.flash" = false;
      "com.apple.AppleMultitouchTrackpad".TrackpadThreeFingerHorizSwipeGesture = 0;
      "com.apple.AppleMultitouchTrackpad".TrackpadThreeFingerVertSwipeGesture = 0;
      "com.apple.AppleMultitouchTrackpad".TrackpadPinchGesture = 0;
      "com.apple.AppleMultitouchTrackpad".TrackpadFourFingerHorizSwipeGesture = 0;
      "com.apple.AppleMultitouchTrackpad".TrackpadFourFingerVertSwipeGesture = 0;
      "com.apple.AppleMultitouchTrackpad".TrackpadFiveFingerPinchGesture = 0;
      "com.apple.dock".showMissionControlGestureEnabled = false;
      "com.apple.dock".showAppExposeGestureEnabled = false;
      "com.apple.dock".showLaunchpadGestureEnabled = false;
      "com.apple.dock".showDesktopGestureEnabled = false;
      "com.apple.dock"."wvous-tl-corner" = 0;
      "com.apple.dock"."wvous-tl-modifier" = 0;
      "com.apple.dock"."wvous-tr-corner" = 0;
      "com.apple.dock"."wvous-tr-modifier" = 0;
      "com.apple.dock"."wvous-bl-corner" = 0;
      "com.apple.dock"."wvous-bl-modifier" = 0;
      "com.apple.dock"."wvous-br-corner" = 0;
      "com.apple.dock"."wvous-br-modifier" = 0;
      "com.apple.finder".NewWindowTargetPath = "file://${userConfig.homeDirectory}/";
      # Driver-level trackpad prefs (override the user-level domain on modern macOS)
      "com.apple.driver.AppleBluetoothMultitouch.trackpad".TrackpadThreeFingerHorizSwipeGesture = 0;
      "com.apple.driver.AppleBluetoothMultitouch.trackpad".TrackpadThreeFingerVertSwipeGesture = 0;
      "com.apple.driver.AppleBluetoothMultitouch.trackpad".TrackpadPinchGesture = 0;
      "com.apple.finder".NSUserKeyEquivalents = {
        "Open" = "\U0d"; # Return/Enter key
      };
    };
  };

  nix.enable = false;

  # Exclude /nix from indexing — saves from searching through the massive nix store
  system.activationScripts.excludeNixFromSpotlight.text = ''
    touch /nix/.metadata_never_index 2>/dev/null || true
  '';

  # Centralized preferences-daemon reload, run after all app modules'
  # postActivation blocks, as a fallback for anything that doesn't manage
  # its own reload (e.g. Raycast, which writes prefs but is never
  # killed/relaunched — it just needs cfprefsd refreshed eventually).
  #
  # Apps that relaunch a fresh process in the same activation pass (Boring
  # Notch, Stats, LinearMouse, MiddleClick) do their OWN local
  # `killall cfprefsd` + app kill before their `open -a` step — otherwise
  # the freshly-launched process reads stale cached prefs, since this
  # centralized kill runs last (lib.mkOrder 2000).
  system.activationScripts.postActivation.text = lib.mkOrder 2000 ''
    echo "Reloading preferences daemon..." >&2
    sudo -u "${userConfig.username}" /usr/bin/killall cfprefsd >/dev/null 2>&1 || true
  '';

  # Cachix substituter — nix.enable = false (Determinate Nix manages nix daemon),
  # so nix.settings doesn't apply. Determinate Nix !include's nix.custom.conf
  # from its managed nix.conf, so we write the substituter config there.
  environment.etc."nix/nix.custom.conf".text = ''
    # bojan-dotfiles cachix
    extra-substituters = https://bojan-dotfiles.cachix.org
    extra-trusted-public-keys = bojan-dotfiles.cachix.org-1:35eXWoN9Ob91Tn6cEhgLJ+6a09KMnZfRzKHbkQrPOX0=

    # Silence "Git tree has uncommitted changes" warning
    warn-dirty = false
  '';

  system.stateVersion = userConfig.darwinSystemVersion;
}
