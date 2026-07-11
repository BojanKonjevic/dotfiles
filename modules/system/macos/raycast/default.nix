{
  pkgs,
  userConfig,
  lib,
  ...
}: let
  spotlightPlist = pkgs.writeText "spotlight-plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>AppleSymbolicHotKeys</key>
      <dict>
        <key>64</key>
        <dict>
          <key>enabled</key>
          <false/>
          <key>value</key>
          <dict>
            <key>type</key>
            <string>standard</string>
            <key>parameters</key>
            <array>
              <integer>32</integer>
              <integer>49</integer>
              <integer>1048576</integer>
            </array>
          </dict>
        </dict>
      </dict>
    </dict>
    </plist>
  '';

  raycastPrefsPlist = pkgs.writeText "raycast-prefs.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>raycastGlobalHotkey</key>
      <string>Command-49</string>
      <key>raycastPreferredWindowMode</key>
      <string>compact</string>
    </dict>
    </plist>
  '';
in {
  homebrew.casks = ["raycast"];

  home-manager.users.${userConfig.username}.home.activation = {
    disableSpotlightHotkey = ''
      target="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
      /usr/libexec/PlistBuddy -c "Merge ${spotlightPlist}" "$target" 2>/dev/null || true
    '';

    raycastPrefs = ''
      target="$HOME/Library/Preferences/com.raycast.macos.plist"
      /usr/bin/defaults import com.raycast.macos "${raycastPrefsPlist}"
    '';
  };
}
