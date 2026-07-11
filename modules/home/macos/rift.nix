{
  config,
  lib,
  pkgs,
  theme,
  userConfig,
  ...
}: let
  brewPrefix = "/opt/homebrew";
  activeBorder = "0xff${lib.removePrefix "#" theme.mauve}";
  inactiveBorder = "0xff${lib.removePrefix "#" theme.surface1}";

  ksd = pkgs.runCommand "keystroke-daemon" {} ''
    unset SDKROOT DEVELOPER_DIR
    mkdir -p "$out/bin"
    /usr/bin/clang -o "$out/bin/ksd" ${./ksd.c} \
      -framework CoreFoundation \
      -framework CoreGraphics \
      -Wall -O2
  '';

  blockCmd = pkgs.runCommand "block-cmd" {} ''
    unset SDKROOT DEVELOPER_DIR
    mkdir -p "$out/bin"
    /usr/bin/clang -o "$out/bin/block-cmd" ${./block-cmd.c} \
      -framework CoreFoundation \
      -framework CoreGraphics \
      -Wall -O2
  '';

  cursorHide = pkgs.runCommand "cursor-hide" {} ''
    unset SDKROOT DEVELOPER_DIR
    mkdir -p "$out/bin"
    /usr/bin/clang -o "$out/bin/cursor-hide" ${./cursor-hide.m} \
      -framework AppKit \
      -framework CoreFoundation \
      -framework CoreGraphics \
      -Wall -O2
  '';

  fifoPath = "/tmp/close-window.fifo";
  fifoPathNew = "/tmp/new-window.fifo";
  fifoPathQuit = "/tmp/quit-app.fifo";

  closeWindow = pkgs.writeShellScriptBin "close-window" ''
    echo > "${fifoPath}"
  '';

  newWindow = pkgs.writeShellScriptBin "new-window" ''
    echo > "${fifoPathNew}"
  '';

  quitApp = pkgs.writeShellScriptBin "quit-app" ''
    echo > "${fifoPathQuit}"
  '';

  bringWindow = pkgs.writeShellScriptBin "bring-window" ''
    ${brewPrefix}/bin/rift-cli execute workspace move-window "$1"
    ${brewPrefix}/bin/rift-cli execute workspace switch "$1"
  '';

  notesWindow = pkgs.writeShellScriptBin "notes-window" ''
    open -n -a Ghostty --args \
      --title="notes-scratch" \
      --window-save-state=never \
      -e /bin/zsh -c 'exec nvim "${userConfig.notesFile}"'

    for i in $(seq 1 10); do
      sleep 0.05
      /usr/bin/osascript -e '
        set W to 960
        set H to 540
        tell application "Finder"
          set {0, 0, sW, sH} to bounds of window of desktop
        end tell
        set x to (sW - W) / 2
        set y to (sH - H) / 2.5
        tell application "System Events"
          tell process "Ghostty"
            try
              set win to first window whose title contains "notes-scratch"
              set position of win to {x, y}
              set size of win to {W, H}
              return true
            on error
              return false
            end try
          end tell
        end tell
      ' 2>/dev/null | grep -q true && break
    done
  '';

  workspaceIndicator = pkgs.runCommand "workspace-indicator" {} ''
    unset SDKROOT DEVELOPER_DIR
    mkdir -p "$out/Applications/RiftWSIndicator.app/Contents/MacOS"
    /usr/bin/clang -o "$out/Applications/RiftWSIndicator.app/Contents/MacOS/RiftWSIndicator" ${./rift-ws-indicator.m} \
      -framework AppKit \
      -fobjc-arc \
      -Wall -O2

    mkdir -p "$out/Applications/RiftWSIndicator.app/Contents/Resources"
    cat > "$out/Applications/RiftWSIndicator.app/Contents/Info.plist" <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleExecutable</key>
      <string>RiftWSIndicator</string>
      <key>CFBundleIdentifier</key>
      <string>org.nix-community.RiftWSIndicator</string>
      <key>CFBundleName</key>
      <string>Rift Workspace Indicator</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>LSUIElement</key>
      <true/>
    </dict>
    </plist>
    EOF
    /usr/bin/plutil -convert binary1 "$out/Applications/RiftWSIndicator.app/Contents/Info.plist"

    mkdir -p "$out/bin"
    ln -s "$out/Applications/RiftWSIndicator.app/Contents/MacOS/RiftWSIndicator" "$out/bin/rift-ws-indicator"
  '';
in {
  home.packages = [closeWindow newWindow quitApp bringWindow notesWindow workspaceIndicator ksd blockCmd cursorHide];
  xdg.configFile."rift/config.toml".text = ''
    [settings]
    animate = false
    hot_reload = true
    focus_follows_mouse = true
    mouse_follows_focus = false
    mouse_hides_on_focus = true
    auto_focus_blacklist = [
      "com.apple.dock",
      "com.apple.systemuiserver",
      "com.raycast.macos",
      "com.apple.controlcenter",
    ]

    [settings.ui.menu_bar]
    enabled = false

    [settings.gestures]
    enabled = false

    [settings.layout]
    mode = "bsp"

    [settings.layout.gaps.outer]
    top = ${toString theme.gapsOut}
    left = ${toString theme.gapsOut}
    bottom = ${toString theme.gapsOut}
    right = ${toString theme.gapsOut}

    [settings.layout.gaps.inner]
    horizontal = ${toString theme.gapsIn}
    vertical = ${toString theme.gapsIn}

    [virtual_workspaces]
    enabled = true
    default_workspace_count = 10
    auto_assign_windows = true
    preserve_focus_per_workspace = true
    workspace_auto_back_and_forth = false

    app_rules = [
      { title_substring = "Preferences", floating = true },
      { title_substring = "Settings", floating = true },
      { ax_subrole = "AXDialog", floating = true },
      { app_id = "com.mitchellh.ghostty", title_substring = "notes-scratch", floating = true },
      { app_name = "System Information", manage = false },
      { app_name = "System Settings", manage = false },
      { app_name = "About This Mac", manage = false },
    ]

    [modifier_combinations]
    mod = "Alt"
    modShift = "Alt + Shift"

    [keys]
    "Alt + Z" = "toggle_space_activated"
    "mod + H" = { move_focus = "left" }
    "mod + J" = { move_focus = "down" }
    "mod + K" = { move_focus = "up" }
    "mod + L" = { move_focus = "right" }

    "modShift + H" = { move_node = "left" }
    "modShift + J" = { move_node = "down" }
    "modShift + K" = { move_node = "up" }
    "modShift + L" = { move_node = "right" }

    "mod + 1" = { switch_to_workspace = 0 }
    "mod + 2" = { switch_to_workspace = 1 }
    "mod + 3" = { switch_to_workspace = 2 }
    "mod + 4" = { switch_to_workspace = 3 }
    "mod + 5" = { switch_to_workspace = 4 }
    "mod + 6" = { switch_to_workspace = 5 }
    "mod + 7" = { switch_to_workspace = 6 }
    "mod + 8" = { switch_to_workspace = 7 }
    "mod + 9" = { switch_to_workspace = 8 }
    "mod + 0" = { switch_to_workspace = 9 }

    "modShift + 1" = { exec = ["${bringWindow}/bin/bring-window", "0"] }
    "modShift + 2" = { exec = ["${bringWindow}/bin/bring-window", "1"] }
    "modShift + 3" = { exec = ["${bringWindow}/bin/bring-window", "2"] }
    "modShift + 4" = { exec = ["${bringWindow}/bin/bring-window", "3"] }
    "modShift + 5" = { exec = ["${bringWindow}/bin/bring-window", "4"] }
    "modShift + 6" = { exec = ["${bringWindow}/bin/bring-window", "5"] }
    "modShift + 7" = { exec = ["${bringWindow}/bin/bring-window", "6"] }
    "modShift + 8" = { exec = ["${bringWindow}/bin/bring-window", "7"] }
    "modShift + 9" = { exec = ["${bringWindow}/bin/bring-window", "8"] }
    "modShift + 0" = { exec = ["${bringWindow}/bin/bring-window", "9"] }

    "mod + Q" = { exec = ["${closeWindow}/bin/close-window"] }
    "modShift + Q" = { exec = ["${quitApp}/bin/quit-app"] }
    "mod + V" = "toggle_window_floating"
    "mod + F" = "toggle_fullscreen"
    "mod + Slash" = "toggle_orientation"
    "mod + E" = { exec = ["open", "-n", "/System/Library/CoreServices/Finder.app"] }
    "mod + N" = { exec = ["${newWindow}/bin/new-window"] }
    "mod + Space" = { exec = ["open", "-a", "/Applications/Raycast.app"] }
    "mod + O" = { exec = ["${notesWindow}/bin/notes-window"] }
    "mod + Escape" = { exec = ["cliclick", "c:."] }
    "mod + Minus" = "resize_window_shrink"
    "mod + Equal" = "resize_window_grow"
  '';

  xdg.configFile."borders/bordersrc" = {
    text = ''
      #! /bin/bash
      options=(
        style=round
        width=${toString theme.borderSize}
        hidpi=on
        active_color=${activeBorder}
        inactive_color=${inactiveBorder}
        order=above
        blacklist="zen"
      )
      borders "''${options[@]}"
    '';
    executable = true;
  };

  launchd.agents.rift = {
    enable = true;
    config = {
      ProgramArguments = ["${./../../../lib/bin/rift-helper}"];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/rift.stdout.log";
      StandardErrorPath = "/tmp/rift.stderr.log";
      EnvironmentVariables = {
        PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:${brewPrefix}/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };

  launchd.agents.borders = {
    enable = true;
    config = {
      ProgramArguments = ["${pkgs.bash}/bin/bash" "${config.xdg.configHome}/borders/bordersrc"];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/borders.stdout.log";
      StandardErrorPath = "/tmp/borders.stderr.log";
      EnvironmentVariables = {
        XDG_CONFIG_HOME = "${config.xdg.configHome}";
        PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:${brewPrefix}/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };

  launchd.agents.quit-app = {
    enable = true;
    config = {
      ProgramArguments = ["${ksd}/bin/ksd" "${fifoPathQuit}" "12"];
      KeepAlive = true;
      RunAtLoad = true;
      ThrottleInterval = 10;
      StandardOutPath = "/tmp/ksd-quit.stdout.log";
      StandardErrorPath = "/tmp/ksd-quit.stderr.log";
      EnvironmentVariables = {
        PATH = "/usr/bin:/bin";
      };
    };
  };

  launchd.agents.close-window = {
    enable = true;
    config = {
      ProgramArguments = ["${ksd}/bin/ksd" "${fifoPath}" "13"];
      KeepAlive = true;
      RunAtLoad = true;
      ThrottleInterval = 10;
      StandardOutPath = "/tmp/ksd-close.stdout.log";
      StandardErrorPath = "/tmp/ksd-close.stderr.log";
      EnvironmentVariables = {
        PATH = "/usr/bin:/bin";
      };
    };
  };

  launchd.agents.new-window = {
    enable = true;
    config = {
      ProgramArguments = ["${ksd}/bin/ksd" "${fifoPathNew}" "45"];
      KeepAlive = true;
      RunAtLoad = true;
      ThrottleInterval = 10;
      StandardOutPath = "/tmp/ksd-new.stdout.log";
      StandardErrorPath = "/tmp/ksd-new.stderr.log";
      EnvironmentVariables = {
        PATH = "/usr/bin:/bin";
      };
    };
  };

  launchd.agents.block-cmd = {
    enable = true;
    config = {
      ProgramArguments = ["${blockCmd}/bin/block-cmd"];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/block-cmd.stdout.log";
      StandardErrorPath = "/tmp/block-cmd.stderr.log";
      EnvironmentVariables = {
        PATH = "/usr/bin:/bin";
      };
    };
  };

  launchd.agents.cursor-hide = {
    enable = true;
    config = {
      ProgramArguments = ["${cursorHide}/bin/cursor-hide"];
      KeepAlive = true;
      RunAtLoad = true;
      ThrottleInterval = 10;
      StandardOutPath = "/tmp/cursor-hide.stdout.log";
      StandardErrorPath = "/tmp/cursor-hide.stderr.log";
      EnvironmentVariables = {
        PATH = "/usr/bin:/bin";
      };
    };
  };

  launchd.agents.workspace-indicator = {
    enable = true;
    config = {
      ProgramArguments = ["${workspaceIndicator}/Applications/RiftWSIndicator.app/Contents/MacOS/RiftWSIndicator"];
      KeepAlive = true;
      RunAtLoad = true;
      ThrottleInterval = 10;
      StandardOutPath = "/tmp/ws-indicator.stdout.log";
      StandardErrorPath = "/tmp/ws-indicator.stderr.log";
      EnvironmentVariables = {
        PATH = "${brewPrefix}/bin:/usr/bin:/bin";
      };
    };
  };
}
