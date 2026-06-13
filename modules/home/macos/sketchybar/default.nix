{
  config,
  theme,
  ...
}: let
  cfgDir = ".config/sketchybar";
  pluginsDir = "${cfgDir}/plugins";
  scriptPath = name: "${config.home.homeDirectory}/${pluginsDir}/${name}";
in {
  home.file = {
    "${cfgDir}/sketchybarrc".text = ''
      -- ── Catppuccin Mocha ────────────────────────────────────────────────────
      local colors = {
        base     = 0xff${builtins.substring 1 6 theme.base};
        mantle   = 0xff${builtins.substring 1 6 theme.mantle};
        crust    = 0xff${builtins.substring 1 6 theme.crust};
        surface0 = 0xff${builtins.substring 1 6 theme.surface0};
        surface1 = 0xff${builtins.substring 1 6 theme.surface1};
        surface2 = 0xff${builtins.substring 1 6 theme.surface2};
        overlay0 = 0xff${builtins.substring 1 6 theme.overlay0};
        overlay1 = 0xff${builtins.substring 1 6 theme.overlay1};
        overlay2 = 0xff${builtins.substring 1 6 theme.overlay2};
        subtext0 = 0xff${builtins.substring 1 6 theme.subtext0};
        subtext1 = 0xff${builtins.substring 1 6 theme.subtext1};
        text     = 0xff${builtins.substring 1 6 theme.text};
        mauve    = 0xff${builtins.substring 1 6 theme.mauve};
        red      = 0xff${builtins.substring 1 6 theme.red};
        green    = 0xff${builtins.substring 1 6 theme.green};
        blue     = 0xff${builtins.substring 1 6 theme.blue};
        peach    = 0xff${builtins.substring 1 6 theme.peach};
        sky      = 0xff${builtins.substring 1 6 theme.sky};
      }

      -- ── Bar ──────────────────────────────────────────────────────────────────
      sbar.bar({
        height = 28,
        color = colors.crust,
        margin = 4,
        corner_radius = 8,
        y_offset = 4,
        blur_radius = 60,
        sticky = true,
      })

      -- ── Workspaces ───────────────────────────────────────────────────────────
      for ws = 1, 10 do
        sbar.add("item", "workspace." .. ws, {
          position = "left",
          label = tostring(ws),
          label.font = "JetBrainsMono Nerd Font:Medium:12.0",
          label.color = colors.overlay2,
          padding_left = 5,
          padding_right = 5,
          background.height = 22,
          background.corner_radius = 4,
          background.color = 0x00000000,
          click_script = "aerospace workspace " .. ws,
        })
      end

      -- ── Mic ──────────────────────────────────────────────────────────────────
      sbar.add("item", "mic", {
        position = "right",
        icon = {
          font = "JetBrainsMono Nerd Font:Medium:14.0",
          string = "",
          color = colors.green,
        },
        label.drawing = false,
      })

      -- ── CPU ──────────────────────────────────────────────────────────────────
      sbar.add("item", "cpu", {
        position = "right",
        label.font = "JetBrainsMono Nerd Font:Medium:12.0",
        label.color = colors.text,
        icon.font = "JetBrainsMono Nerd Font:Medium:13.0",
        icon.string = "󰻠",
        icon.color = colors.sky,
        padding_right = 2,
      })

      -- ── Memory ───────────────────────────────────────────────────────────────
      sbar.add("item", "mem", {
        position = "right",
        label.font = "JetBrainsMono Nerd Font:Medium:12.0",
        label.color = colors.text,
        icon.font = "JetBrainsMono Nerd Font:Medium:13.0",
        icon.string = "󰍛",
        icon.color = colors.blue,
        padding_right = 2,
      })

      -- ── Events ───────────────────────────────────────────────────────────────
      sbar.add("event", "aerospace_workspace_change")
      sbar.add("item", "workspace-event", { drawing = false, updates = true })
      sbar.subscribe("workspace-event", "aerospace_workspace_change", "${scriptPath "workspaces.sh"}")

      -- ── Background updaters ──────────────────────────────────────────────────
      sbar.exec("${scriptPath "mic.sh"} &")
      sbar.exec("${scriptPath "cpu.sh"} &")
      sbar.exec("${scriptPath "mem.sh"} &")
      sbar.exec("${scriptPath "workspaces.sh"} &")
    '';

    "${pluginsDir}/workspaces.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null || echo "1")
        OCCUPIED=$(aerospace list-workspaces --monitor all --empty no 2>/dev/null || echo "")

        for WS in 1 2 3 4 5 6 7 8 9 10; do
          if [ "$WS" = "$FOCUSED" ]; then
            sketchybar --set workspace.$WS \
              label.color=0xff${builtins.substring 1 6 theme.mauve} \
              background.color=0x2e${builtins.substring 1 6 theme.mauve}
          elif echo "$OCCUPIED" | grep -qw "$WS"; then
            sketchybar --set workspace.$WS \
              label.color=0xbf${builtins.substring 1 6 theme.text} \
              background.color=0x00000000
          else
            sketchybar --set workspace.$WS \
              label.color=0x40${builtins.substring 1 6 theme.overlay2} \
              background.color=0x00000000
          fi
        done
      '';
    };

    "${pluginsDir}/mic.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        while true; do
          STATE=$(cat /tmp/qs-mic-state 2>/dev/null || echo "unknown")
          if [ "$STATE" = "muted" ]; then
            sketchybar --set mic icon="" icon.color=0xff${builtins.substring 1 6 theme.red}
          else
            sketchybar --set mic icon="" icon.color=0xff${builtins.substring 1 6 theme.green}
          fi
          sleep 1
        done
      '';
    };

    "${pluginsDir}/cpu.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        while true; do
          CPU=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
          sketchybar --set cpu label="''${CPU}%"
          sleep 5
        done
      '';
    };

    "${pluginsDir}/mem.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        while true; do
          MEM=$(memory_pressure | grep "System-wide memory free percentage:" | awk '{print $5}' | sed 's/%//')
          USED=$((100 - MEM))
          sketchybar --set mem label="''${USED}%"
          sleep 5
        done
      '';
    };
  };
}
