{
  config,
  lib,
  theme,
  userConfig,
  ...
}: let
  brewPrefix = userConfig.brewPrefix;
  activeBorder = "0xff${lib.removePrefix "#" theme.mauve}";
  inactiveBorder = "0xff${lib.removePrefix "#" theme.surface1}";
in {
  xdg.configFile."rift/config.toml".text = ''
    [settings]
    animate = true
    animation_duration = 0.2
    animation_fps = 60
    hot_reload = true
    focus_follows_mouse = true
    mouse_follows_focus = false
    mouse_hides_on_focus = true
    auto_focus_blacklist = [
      "com.apple.dock"
      "com.apple.systemuiserver"
      "com.raycast.macos"
      "com.apple.controlcenter"
    ]

    [settings.gestures]
    enabled = true
    fingers = 3
    consume_dock_swipe = true
    skip_empty = true
    haptics_enabled = true
    haptic_pattern = "level_change"

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
    workspace_auto_back_and_forth = true

    app_rules = [
      { title_substring = "Preferences", floating = true }
      { title_substring = "Settings", floating = true }
      { ax_subrole = "AXDialog", floating = true }
      { app_name = "System Information", manage = false }
      { app_name = "System Settings", manage = false }
      { app_name = "About This Mac", manage = false }
    ]

    [modifier_combinations]
    mod = "Alt"
    modShift = "Alt + Shift"

    [keys]
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

    "modShift + 1" = { move_window_to_workspace = 0 }
    "modShift + 2" = { move_window_to_workspace = 1 }
    "modShift + 3" = { move_window_to_workspace = 2 }
    "modShift + 4" = { move_window_to_workspace = 3 }
    "modShift + 5" = { move_window_to_workspace = 4 }
    "modShift + 6" = { move_window_to_workspace = 5 }
    "modShift + 7" = { move_window_to_workspace = 6 }
    "modShift + 8" = { move_window_to_workspace = 7 }
    "modShift + 9" = { move_window_to_workspace = 8 }
    "modShift + 0" = { move_window_to_workspace = 9 }

    "mod + Q" = "close_window"
    "mod + V" = "toggle_window_floating"
    "mod + F" = "toggle_fullscreen"
    "mod + Slash" = "toggle_orientation"
    "mod + Comma" = "switch_to_last_workspace"
    "mod + Enter" = { exec = ["kitty"] }
    "mod + Backslash" = { exec = ["mic-toggle"] }
    "modShift + Enter" = { exec = ["kitty"] }
    "mod + E" = { exec = ["open", "-n", "/System/Library/CoreServices/Finder.app"] }
    "mod + N" = { exec = ["open", "-n", "-a", "Zen Browser", "--args", "--private-window"] }
    "mod + Space" = { exec = ["open", "-n", "/Applications/Raycast.app"] }
    "Ctrl + Escape" = { exec = ["cliclick", "c:."] }
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
      )
      borders "''${options[@]}"
    '';
    executable = true;
  };

  launchd.agents.rift = {
    enable = true;
    config = {
      ProgramArguments = ["${brewPrefix}/bin/rift"];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/rift.stdout.log";
      StandardErrorPath = "/tmp/rift.stderr.log";
    };
  };

  launchd.agents.borders = {
    enable = true;
    config = {
      ProgramArguments = ["${brewPrefix}/bin/borders"];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/borders.stdout.log";
      StandardErrorPath = "/tmp/borders.stderr.log";
      EnvironmentVariables = {
        XDG_CONFIG_HOME = "${config.xdg.configHome}";
      };
    };
  };
}
