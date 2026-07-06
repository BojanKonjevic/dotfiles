{
  pkgs,
  userConfig,
  inputs,
  ...
}: {
  # `nixpkgs` is pinned pre-ad97f55 to keep the darwin manual build working
  # (see flake.nix), but that pin's apple-sdk_15 lacks working Swift module
  # maps for DarwinFoundation/Darwin. Overlay just that package back in from
  # a newer nixpkgs so Swift-based home-manager modules (cursor-warp,
  # mic-status-bar) still build.
  nixpkgs.overlays = [
    (final: prev: let
      applePkgs = inputs.nixpkgs-apple-sdk.legacyPackages.${prev.system};
    in {
      apple-sdk_15 = applePkgs.apple-sdk_15;
      swift = applePkgs.swift;
    })
  ];

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
  #system.defaults.universalaccess.reduceTransparency = false;
  nix.enable=false;

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
  '';

  system.defaults.loginwindow = {
    GuestEnabled = false;
    SHOWFULLNAME = true;
  };
  system.stateVersion = userConfig.darwinSystemVersion;
}
