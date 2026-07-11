{
  inputs,
  userConfig,
  pkgs,
  lib,
  ...
}: let
  reloadAppPrefs = import ./reload-app-prefs.nix {inherit userConfig;};
  bundleId = "theboringteam.boringnotch";

  settingsPlist = pkgs.writeText "boringnotch-settings.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeyboardShortcuts_toggleNotchOpen</key>
      <string>{"carbonKeyCode":34,"carbonModifiers":768}</string>

      <key>KeyboardShortcuts_toggleSneakPeek</key>
      <string>{"carbonKeyCode":4,"carbonModifiers":768}</string>

      <key>NSStatusItem VisibleCC Item-0</key>
      <integer>0</integer>

      <key>SUAutomaticallyUpdate</key>
      <true/>
      <key>SUEnableAutomaticChecks</key>
      <false/>
      <key>SUHasLaunchedBefore</key>
      <true/>
      <key>SUSendProfileInfo</key>
      <false/>

      <key>alwaysShowTabs</key>
      <true/>
      <key>autoRemoveShelfItems</key>
      <true/>
      <key>boringShelf</key>
      <true/>
      <key>coloredSpectrogram</key>
      <true/>
      <key>enableGestures</key>
      <false/>
      <key>enableGradient</key>
      <false/>
      <key>enableLyrics</key>
      <true/>
      <key>enableSneakPeek</key>
      <false/>
      <key>extendHoverArea</key>
      <false/>
      <key>firstLaunch</key>
      <false/>
      <key>hideFromScreenRecording</key>
      <true/>
      <key>hideTitleBar</key>
      <true/>
      <key>hudReplacement</key>
      <false/>
      <key>inlineHUD</key>
      <true/>
      <key>lightingEffect</key>
      <true/>
      <key>mediaController</key>
      <string>Now Playing</string>
      <key>menubarIcon</key>
      <false/>
      <key>minimumHoverDuration</key>
      <real>0.1</real>

      <key>musicControlSlots</key>
      <array>
        <string>"shuffle"</string>
        <string>"previous"</string>
        <string>"playPause"</string>
        <string>"next"</string>
        <string>"repeatMode"</string>
      </array>

      <key>musicLiveActivityEnabled</key>
      <true/>
      <key>nonNotchHeightMode</key>
      <string>Match menubar height</string>
      <key>notchHeight</key>
      <integer>38</integer>
      <key>notchHeightMode</key>
      <string>Match real notch height</string>
      <key>openLastTabByDefault</key>
      <false/>
      <key>optionKeyAction</key>
      <string>Open System Settings</string>
      <key>playerColorTinting</key>
      <true/>
      <key>preferred_screen_uuid</key>
      <string>9FF1BE91-BC32-4E92-9D12-711BF38B89F7</string>
      <key>showCalendar</key>
      <false/>
      <key>showClosedNotchHUDPercentage</key>
      <false/>
      <key>showMirror</key>
      <false/>
      <key>showOnAllDisplays</key>
      <true/>
      <key>showOnLockScreen</key>
      <false/>
      <key>sliderUseAlbumArtColor</key>
      <string>Match album art</string>
      <key>systemEventIndicatorShadow</key>
      <true/>
      <key>systemEventIndicatorUseAccent</key>
      <true/>
      <key>useCustomAccentColor</key>
      <false/>
    </dict>
    </plist>
  '';
in {
  nix-homebrew.taps."TheBoredTeam/boring-notch" = inputs.boring-notch-brew;
  nix-homebrew.trust = {
    taps = ["TheBoredTeam/boring-notch"];
    casks = ["TheBoredTeam/boring-notch/boring-notch"];
  };
  homebrew.casks = ["boring-notch"];
  system.activationScripts.postActivation.text = lib.mkAfter (
    reloadAppPrefs {
      inherit bundleId settingsPlist;
      appName = "boringNotch";
      label = "Boring Notch";
    }
  );
}
