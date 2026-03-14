{...}: {
  programs.waybar = {
    enable = true;

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 18px;
        font-weight: 900;
        padding: 0;
        margin: 0;
        border: none;
        min-height: 0;
      }

      window#waybar {
        all: unset;
      }

      .modules-left,
      .modules-center,
      .modules-right {
        padding: 4px 12px;
        border-radius: 12px;
        background: alpha(@mantle, 0.82);
        box-shadow: 0 3px 10px rgba(0,0,0,0.5);
      }

      .modules-left   { margin-left:  4px; }
      .modules-center { margin: 4px 2px 3px; }
      .modules-right  { margin-right: 4px; }

      tooltip {
        background: alpha(@mantle, 0.94);
        border: 1px solid @surface1;
        border-radius: 10px;
        color: @text;
        padding: 8px 12px;
        font-weight: 600;
        box-shadow: 0 4px 12px rgba(0,0,0,0.6);
      }

      #clock {
        color: @mauve;
        padding: 0 12px;
        font-weight: 900;
      }

      #pulseaudio.source {
        color: @green;
        padding: 0 8px;
      }

      #pulseaudio.muted,
      #pulseaudio.source.muted {
        color: @overlay0;
      }

      #pulseaudio.source.muted {
        color: @red;
      }

      #custom-power {
        color: @red;
        padding: 0 10px;
        font-size: 16px;
      }

      #custom-power:hover {
        color: @rosewater;
        background: alpha(@surface2, 0.45);
        border-radius: 8px;
        transition: all 0.2s ease;
      }

      #pulseaudio.source:hover {
        color: @rosewater;
        background: alpha(@surface2, 0.45);
        border-radius: 8px;
        transition: all 0.2s ease;
      }

      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        min-width: 36px;          /* good for 1–10 + some padding */
        padding: 0 8px;
        margin: 0 2px;
        color: alpha(@mauve, 0.85);
        border-radius: 6px;
        transition: all 0.2s ease;
      }

      #workspaces button:hover {
        color: @lavender;
        text-shadow: 0 0 6px alpha(@lavender, 0.6);
        background: alpha(@surface1, 0.45);
      }

      #workspaces button.active {
        color: @lavender;
        background: alpha(@surface2, 0.65);
        text-shadow: 0 0 8px alpha(@lavender, 0.9);
        font-weight: 900;
        border-radius: 8px;
      }

      #workspaces button.empty {
        color: alpha(@overlay1, 0.65);
      }

      #workspaces button.empty:hover {
        color: alpha(@lavender, 0.9);
      }

      #submap {
        color: @red;
        font-weight: bold;
        padding: 0 10px;
        text-shadow: 0 0 7px alpha(@red, 0.65);
      }

      /* Hardware modules */
      #cpu {
        color: @peach;
        padding: 0 9px;
        font-weight: 900;
      }

      #memory {
        color: @blue;
        padding: 0 9px;
        font-weight: 900;
      }
    '';

    settings = {
      main = {
        layer = "top";
        position = "top";
        reload-style-on-change = true;
        spacing = 8;

        modules-left = ["clock"];
        modules-center = ["hyprland/workspaces"];
        modules-right = [
          "hyprland/submap"
          "cpu"
          "memory"
          "pulseaudio#source"
          "custom/power"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          persistent-workspaces = {
            "*" = [1 2 3 4 5];
          };
        };

        "hyprland/submap" = {
          format = "󰩨 {}";
          tooltip = false;
        };

        clock = {
          format = "{:%d %A %I:%M %p}";
          tooltip = false;
          interval = 1;
        };

        "pulseaudio#source" = {
          format = "{format_source}";
          format-source = "󰍬";
          format-source-muted = "<span foreground='#f38ba8'>󰍭</span>";
          tooltip = true;
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        };

        "custom/power" = {
          format = "⏻";
          tooltip = true;
          tooltip-format = "Power menu";
          on-click = "power-menu";
        };

        cpu = {
          interval = 1;
          format = "󰍛 {usage}%";
          tooltip = false;
        };

        memory = {
          interval = 1;
          format = "󰾆 {percentage}%";
          tooltip = false;
        };
      };
    };
  };
}
