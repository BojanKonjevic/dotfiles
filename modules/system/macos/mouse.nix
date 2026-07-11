{
  inputs,
  userConfig,
  pkgs,
  lib,
  ...
}: let
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
in {
  homebrew.casks = ["linearmouse" "middleclick"];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "Applying LinearMouse settings..." >&2

    CONFIG_DIR="${userConfig.homeDirectory}/.config/linearmouse"
    mkdir -p "$CONFIG_DIR"
    cp "${settingsJson}" "$CONFIG_DIR/linearmouse.json"
    chown "${userConfig.username}" "$CONFIG_DIR/linearmouse.json"

    sudo -u "${userConfig.username}" /usr/bin/defaults write "${bundleId}" autoSwitchToActiveDevice -bool false
    sudo -u "${userConfig.username}" /usr/bin/defaults write "${bundleId}" menuBarVisibilityMode -string '"never"'
    sudo -u "${userConfig.username}" /usr/bin/defaults write "${bundleId}" selectedDevice -string '{"category":"mouse"}'
    sudo -u "${userConfig.username}" /usr/bin/defaults write "${bundleId}" showInDock -bool false
    sudo -u "${userConfig.username}" /usr/bin/defaults write "${bundleId}" showInMenuBar -bool false
    sudo -u "${userConfig.username}" /usr/bin/defaults write "${bundleId}" SUEnableAutomaticChecks -bool false
    sudo -u "${userConfig.username}" /usr/bin/killall cfprefsd >/dev/null 2>&1 || true

    echo "Applying MiddleClick settings..." >&2
    sudo -u "${userConfig.username}" /usr/bin/defaults write art.ginzburg.MiddleClick "NSStatusItem VisibleCC Item-0" -bool false
    sudo -u "${userConfig.username}" /usr/bin/killall cfprefsd >/dev/null 2>&1 || true
    sudo -u "${userConfig.username}" /usr/bin/killall MiddleClick >/dev/null 2>&1 || true
  '';
}
