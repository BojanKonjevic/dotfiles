{
  pkgs,
  lib,
  userConfig,
  ...
}: let
  reloadAppPrefs = import ./reload-app-prefs.nix {inherit userConfig;};
  bundleId = "com.lujjjh.LinearMouse";

  settingsJson = pkgs.writeText "linearmouse.json" ''
    {
      "$schema" : "https://schema.linearmouse.app/0.11.3",
      "schemes" : [
        {
          "buttons" : {
            "universalBackForward" : true
          },
          "if" : {
            "device" : {
              "category" : "mouse"
            }
          },
          "pointer" : {
            "acceleration" : 1.0000,
            "disableAcceleration" : true
          },
          "scrolling" : {
            "acceleration" : {
              "vertical" : 1
            },
            "distance" : {
              "vertical" : "auto"
            },
            "modifiers" : {
              "vertical" : {
                "command" : {
                  "type" : "zoom"
                },
                "control" : {
                  "type" : "preventDefault"
                },
                "option" : {
                  "type" : "pinchZoom"
                },
                "shift" : {
                  "type" : "preventDefault"
                }
              }
            },
            "reverse" : {
              "vertical" : true
            },
            "smoothed" : {
              "vertical" : {
                "acceleration" : 1.1,
                "bouncing" : true,
                "enabled" : true,
                "inertia" : 0.74,
                "preset" : "easeInOut",
                "response" : 0.68,
                "speed" : 0
              }
            },
            "speed" : {
              "vertical" : 0
            }
          }
        }
      ]
    }
  '';

  settingsPlist = pkgs.writeText "linearmouse-prefs.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>autoSwitchToActiveDevice</key>
      <false/>
      <key>menuBarVisibilityMode</key>
      <string>&quot;never&quot;</string>
      <key>selectedDevice</key>
      <string>{"category":"mouse"}</string>
      <key>showInDock</key>
      <false/>
      <key>showInMenuBar</key>
      <false/>
      <key>SUEnableAutomaticChecks</key>
      <false/>
    </dict>
    </plist>
  '';

  middleClickBundleId = "art.ginzburg.MiddleClick";

  middleClickPlist = pkgs.writeText "middleclick-prefs.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>NSStatusItem VisibleCC Item-0</key>
      <false/>
    </dict>
    </plist>
  '';
in {
  homebrew.casks = ["linearmouse" "middleclick"];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    CONFIG_DIR="${userConfig.homeDirectory}/.config/linearmouse"
    mkdir -p "$CONFIG_DIR"
    if ! /usr/bin/cmp -s "${settingsJson}" "$CONFIG_DIR/linearmouse.json" 2>/dev/null; then
      cp "${settingsJson}" "$CONFIG_DIR/linearmouse.json"
      chown "${userConfig.username}" "$CONFIG_DIR/linearmouse.json"
    fi

    ${reloadAppPrefs {
      inherit bundleId settingsPlist;
      appName = "LinearMouse";
    }}

    ${reloadAppPrefs {
      bundleId = middleClickBundleId;
      settingsPlist = middleClickPlist;
      appName = "MiddleClick";
    }}
  '';
}
