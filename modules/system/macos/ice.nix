{
  inputs,
  userConfig,
  pkgs,
  lib,
  ...
}: let
  bundleId = "com.jordanbaird.Ice";

  # MenuBarAppearanceConfigurationV2 is a large JSON blob encoding the full
  # menu bar layout (section assignments, ordering, spacing, colors). It's
  # omitted because embedding 47KB of base64 is not practical — reconfigure
  # in Ice's GUI after a fresh install.
  settingsPlist = pkgs.writeText "ice-settings.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>AutoRehide</key>
      <true/>
      <key>CanToggleAlwaysHiddenSection</key>
      <true/>
      <key>CustomIceIconIsTemplate</key>
      <false/>
      <key>EnableAlwaysHiddenSection</key>
      <false/>
      <key>HideApplicationMenus</key>
      <true/>
      <key>Hotkeys</key>
      <dict>
        <key>EnableIceBar</key>
        <data>
        bnVsbA==
        </data>
        <key>SearchMenuBarItems</key>
        <data>
        bnVsbA==
        </data>
        <key>ShowSectionDividers</key>
        <data>
        bnVsbA==
        </data>
        <key>ToggleAlwaysHiddenSection</key>
        <data>
        bnVsbA==
        </data>
        <key>ToggleApplicationMenus</key>
        <data>
        bnVsbA==
        </data>
        <key>ToggleHiddenSection</key>
        <data>
        bnVsbA==
        </data>
      </dict>
      <key>IceBarLocation</key>
      <integer>0</integer>
      <key>IceIcon</key>
      <data>
      eyJoaWRkZW4iOnsiY2F0YWxvZyI6eyJfMCI6IkRvdEZpbGwifX0sInZpc2libGUiOnsi
      Y2F0YWxvZyI6eyJfMCI6IkRvdFN0cm9rZSJ9fSwibmFtZSI6IkRvdCJ9
      </data>
      <key>ItemSpacingOffset</key>
      <real>0.0</real>
      <key>NSSplitView Subview Frames SettingsWindow, SidebarNavigationSplitView</key>
      <array>
        <string>0.000000, 0.000000, 210.000000, 1039.000000, NO, NO</string>
        <string>211.000000, 0.000000, 1699.000000, 1039.000000, NO, NO</string>
      </array>
      <key>NSStatusItem Preferred Position HItem</key>
      <real>303</real>
      <key>NSStatusItem Preferred Position SItem</key>
      <real>270</real>
      <key>NSStatusItem VisibleCC AHItem</key>
      <false/>
      <key>NSStatusItem VisibleCC SItem</key>
      <true/>
      <key>NSWindow Frame PermissionsWindow</key>
      <string>5 407 493 637 0 0 1920 1050 </string>
      <key>NSWindow Frame SettingsWindow</key>
      <string>10 0 1910 1039 0 0 1920 1050 </string>
      <key>RehideInterval</key>
      <real>15</real>
      <key>RehideStrategy</key>
      <integer>0</integer>
      <key>SUAutomaticallyUpdate</key>
      <false/>
      <key>SUEnableAutomaticChecks</key>
      <false/>
      <key>SUHasLaunchedBefore</key>
      <true/>
      <key>SUSendProfileInfo</key>
      <false/>
      <key>ShowAllSectionsOnUserDrag</key>
      <true/>
      <key>ShowIceIcon</key>
      <true/>
      <key>ShowOnClick</key>
      <true/>
      <key>ShowOnHover</key>
      <true/>
      <key>ShowOnHoverDelay</key>
      <real>0.20000000000000001</real>
      <key>ShowOnScroll</key>
      <false/>
      <key>ShowSectionDividers</key>
      <false/>
      <key>TempShowInterval</key>
      <real>15</real>
      <key>UseIceBar</key>
      <false/>
      <key>hasMigrated0_10_0</key>
      <true/>
      <key>hasMigrated0_10_1</key>
      <true/>
      <key>hasMigrated0_8_0</key>
      <true/>
    </dict>
    </plist>
  '';
in {
  homebrew.casks = ["jordanbaird-ice"];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "Applying Ice settings..." >&2
    sudo -u "${userConfig.username}" defaults import "${bundleId}" "${settingsPlist}"
    sudo -u "${userConfig.username}" killall cfprefsd >/dev/null 2>&1 || true
    sudo -u "${userConfig.username}" killall Ice >/dev/null 2>&1 || true
  '';
}
