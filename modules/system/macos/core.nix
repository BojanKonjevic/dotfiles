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
      AppleInterfaceStyleSwitchesAutomatically = false;
      AppleKeyboardUIMode = 3;
      ApplePressAndHoldEnabled = false;
      AppleShowScrollBars = "WhenScrolling";
      AppleScrollerPagingBehavior = true;
      AppleSpacesSwitchOnActivate = true;
      AppleWindowTabbingMode = "manual";
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticWindowAnimationsEnabled = false;
      NSDisableAutomaticTermination = true;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSTableViewDefaultSizeMode = 2;
      NSWindowShouldDragOnGesture = true;
      "com.apple.keyboard.fnState" = true;
      "com.apple.springing.enabled" = true;
      "com.apple.springing.delay" = 0.5;
      "com.apple.trackpad.forceClick" = true;
    };

    dock = {
      autohide = true;
      autohide-delay = 999999.0;
      autohide-time-modifier = 0.0;
      mru-spaces = false;
      showDesktopGestureEnabled = false;
      showAppExposeGestureEnabled = false;
      showLaunchpadGestureEnabled = false;
      showMissionControlGestureEnabled = false;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowPathbar = true;
      FXPreferredViewStyle = "icnv";
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      NewWindowTarget = "Home";
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
      FXRemoveOldTrashItems = true;
    };

    screencapture = {
      location = userConfig.screenshotsDir;
      type = "png";
      disable-shadow = true;
      show-thumbnail = false;
      target = "file";
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
      TrackpadThreeFingerTapGesture = 0;
      TrackpadThreeFingerHorizSwipeGesture = 0;
      TrackpadThreeFingerVertSwipeGesture = 0;
      TrackpadFourFingerHorizSwipeGesture = 0;
      TrackpadFourFingerVertSwipeGesture = 0;
      TrackpadFourFingerPinchGesture = 0;
    };

    menuExtraClock = {
      ShowAMPM = true;
      ShowDayOfWeek = true;
      ShowDate = 0;
      Show24Hour = true;
      ShowSeconds = false;
    };

    controlcenter = {
      BatteryShowPercentage = true;
      Sound = true;
      Bluetooth = true;
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

    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    spaces = {
      spans-displays = false;
    };

    LaunchServices = {
      LSQuarantine = false;
    };

    hitoolbox = {
      AppleFnUsageType = "Do Nothing";
    };

    CustomUserPreferences = {
      "com.apple.Siri".StatusMenuVisible = false;
      "com.apple.assistant.support"."Assistant Enabled" = false;
      "com.apple.Siri".VoiceTriggerUserEnabled = false;

      "NSGlobalDomain".AppleLocale = userConfig.locale;
      "NSGlobalDomain".AppleMiniaturizeOnDoubleClick = false;
      "NSGlobalDomain"."com.apple.sound.beep.flash" = false;

      "com.apple.AppleMultitouchTrackpad".TrackpadPinchGesture = 0;
      "com.apple.AppleMultitouchTrackpad".TrackpadFiveFingerPinchGesture = 0;

      "com.apple.dock"."wvous-tl-modifier" = 0;
      "com.apple.dock"."wvous-tr-modifier" = 0;
      "com.apple.dock"."wvous-bl-modifier" = 0;
      "com.apple.dock"."wvous-br-modifier" = 0;

      "com.apple.finder".NSUserKeyEquivalents = {
        "Open" = "\U0d";
      };

      "com.apple.driver.AppleBluetoothMultitouch.trackpad".TrackpadPinchGesture = 0;
      "com.apple.driver.AppleBluetoothMultitouch.trackpad".TrackpadFiveFingerPinchGesture = 0;
    };
  };

  networking.applicationFirewall = {
    enable = true;
    allowSigned = true;
    allowSignedApp = true;
    enableStealthMode = true;
  };

  nix.enable = false;

  system.activationScripts.excludeNixFromSpotlight.text = ''
    touch /nix/.metadata_never_index 2>/dev/null || true
  '';

  system.activationScripts.postActivation.text = lib.mkOrder 2000 ''
    echo "Reloading preferences daemon..." >&2
    sudo -u "${userConfig.username}" /usr/bin/killall cfprefsd >/dev/null 2>&1 || true
  '';

  environment.etc."nix/nix.custom.conf".text = ''
    extra-substituters = https://bojan-dotfiles.cachix.org
    extra-trusted-public-keys = bojan-dotfiles.cachix.org-1:35eXWoN9Ob91Tn6cEhgLJ+6a09KMnZfRzKHbkQrPOX0=
    warn-dirty = false
  '';

  system.stateVersion = userConfig.darwinSystemVersion;
}
