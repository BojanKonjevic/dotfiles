{
  pkgs,
  userConfig,
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
  system.defaults.NSGlobalDomain.AppleICUForce24HourTime = true;
  security.pam.services.sudo_local.touchIdAuth = true;

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [];

  programs.zsh.enable = true;
  environment.shells = [pkgs.zsh];
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 999999.0;
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
    NewWindowTarget = "Home";
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
  system.defaults.trackpad = {
    Clicking = true;
    TrackpadRightClick = true;
    TrackpadThreeFingerDrag = true;
  };
  nix.enable = false;

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
    "NSGlobalDomain".AppleEnableSwipeNavigateWithScrolls = false;
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
    # Disable all Hot Corners
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
  };

  # Exclude /nix from indexing — saves from searching through the massive nix store
  system.activationScripts.excludeNixFromSpotlight.text = ''
    touch /nix/.metadata_never_index 2>/dev/null || true
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

  system.defaults.loginwindow = {
    GuestEnabled = false;
    SHOWFULLNAME = true;
  };
  system.stateVersion = userConfig.darwinSystemVersion;
}
