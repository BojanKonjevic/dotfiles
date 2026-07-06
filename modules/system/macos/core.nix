{
  pkgs,
  userConfig,
  inputs,
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
  # Bake the --toc-depth shim into the pkgs import directly so that
  # nix-darwin's buildPackages.nixos-render-docs (used by doc/manual)
  # also gets the wrapped version. nixpkgs.overlays only applies to pkgs,
  # but buildPackages needs it too.
  nixpkgs.pkgs = import inputs.nixpkgs {
    inherit (userConfig) system;
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        nixos-render-docs = prev.writeShellScriptBin "nixos-render-docs" ''
          args=(); skip=0
          for a in "$@"; do
            if [ "$skip" = 1 ]; then skip=0; continue; fi
            case "$a" in
              --toc-depth|--chunk-toc-depth|--section-toc-depth) skip=1 ;;
              --toc-depth=*|--chunk-toc-depth=*|--section-toc-depth=*) ;;
              *) args+=("$a") ;;
            esac
          done
          exec ${prev.nixos-render-docs}/bin/nixos-render-docs "''${args[@]}"
        '';
      })
    ];
  };

  # nixpkgs.config is ignored when nixpkgs.pkgs is set; the config is
  # passed directly to the import above.

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
  system.defaults.universalaccess.reduceTransparency = false;

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

  system.defaults.loginwindow = {
    GuestEnabled = false;
    SHOWFULLNAME = true;
  };
  system.stateVersion = userConfig.darwinSystemVersion;
}
