{
  pkgs,
  userConfig,
  lib,
  ...
}: let
  raycastConfigPath = "Library/Application Support/com.raycast.macOS/config.json";

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
in {
  homebrew.casks = ["raycast"];

  home-manager.users.${userConfig.username}.home.activation = {
    raycastSeed = lib.mkAfter ''
      if [ ! -f "$HOME/${raycastConfigPath}" ]; then
        mkdir -p "$HOME/Library/Application Support/com.raycast.macOS"
        cp ${./config.json} "$HOME/${raycastConfigPath}"
      fi
    '';

    disableSpotlightHotkey = ''
      target="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
      /usr/libexec/PlistBuddy -c "Merge ${spotlightPlist}" "$target" 2>/dev/null || true
      /usr/bin/killall cfprefsd 2>/dev/null || true
    '';
  };
}
