{
  theme,
  pkgs,
  ...
}: {
  home.packages = [pkgs.networkmanagerapplet];

  programs.waybar = {
    enable = true;

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 17px;
        font-weight: 900;
        padding: 0;
        margin: 0;
        border: none;
        min-height: 0;
      }

      window#waybar {
        background: alpha(@crust, 0.60);
        border-bottom: 1px solid alpha(@mauve, 0.35);
      }

      .modules-left,
      .modules-center,
      .modules-right {
        background: transparent;
        box-shadow: none;
        border-radius: 0;
        padding: 0 10px;
      }

      tooltip {
        background: alpha(@mantle, 0.96);
        border: 1px solid @surface1;
        border-radius: 8px;
        color: @text;
        padding: 6px 10px;
        font-weight: 600;
        box-shadow: 0 4px 12px rgba(0,0,0,0.6);
      }

      #clock {
        color: @mauve;
        padding: 0 10px 0 4px;
        font-weight: 900;
        border-right: 1px solid alpha(@surface1, 0.6);
      }

      #custom-weather {
        color: @text;
        padding: 0 0 0 10px;
        font-weight: 900;
      }

      #workspaces {
        padding: 0;
      }

      #workspaces button {
        min-width: 32px;
        padding: 0 6px;
        margin: 0 1px;
        color: alpha(@lavender, 0.75);
        border-radius: 0;
        transition: color 0.15s ease;
        background: transparent;
        font-size: 17px;
        font-weight: 900;
        text-shadow: 0 0 8px alpha(@lavender, 0.5);
      }

      #workspaces button:hover {
        color: @lavender;
        background: alpha(@surface0, 0.5);
      }

      #workspaces button.active {
        color: @mauve;
        background: alpha(@surface0, 0.6);
        border-bottom: 2px solid @mauve;
        font-weight: 900;
        text-shadow: 0 0 10px alpha(@mauve, 0.8);
      }

      #workspaces button.empty {
        color: alpha(@overlay2, 0.6);
        text-shadow: none;
        font-weight: 700;
      }

      #submap {
        color: @red;
        font-weight: bold;
        padding: 0 8px;
      }

      #cpu {
        color: @peach;
        padding: 0 8px;
      }

      #memory {
        color: @blue;
        padding: 0 8px;
        border-right: 1px solid alpha(@surface1, 0.6);
      }

      #network {
        color: @sky;
        padding: 0 8px;
      }

      #network.disconnected {
        color: @overlay0;
      }

      #pulseaudio.source {
        color: @green;
        padding: 0 8px;
      }

      #pulseaudio.source.muted {
        color: @red;
      }

      #custom-power {
        color: alpha(@overlay1, 0.8);
        padding: 0 10px 0 6px;
        font-size: 17px;
        border-left: 1px solid alpha(@surface1, 0.6);
      }

      #custom-power:hover {
        color: @red;
        transition: color 0.15s ease;
      }
    '';

    settings = {
      main = {
        layer = "top";
        position = "top";
        height = 28;
        margin-top = 0;
        margin-left = 0;
        margin-right = 0;
        reload-style-on-change = true;
        spacing = 0;
        exclusive = true;

        modules-left = ["clock" "custom/weather"];
        modules-center = ["hyprland/workspaces"];
        modules-right = [
          "hyprland/submap"
          "cpu"
          "memory"
          "network"
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

        network = {
          format-wifi = "󰤨";
          format-ethernet = "󰈀";
          format-disconnected = "󰤭";
          tooltip = true;
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          tooltip-format-ethernet = "{ifname}";
          tooltip-format-disconnected = "Disconnected";
          on-click = "nm-connection-editor";
        };

        "pulseaudio#source" = {
          format = "{format_source}";
          format-source = "󰍬";
          format-source-muted = "<span foreground='${theme.red}'>󰍭</span>";
          tooltip = true;
          on-click = "mic-toggle";
        };

        "custom/weather" = {
          exec = "weather --bar";
          return-type = "json";
          interval = 600;
          on-click = "kitty --hold weather";
          tooltip = true;
        };

        "custom/power" = {
          format = "⏻";
          tooltip = true;
          tooltip-format = "Power menu";
          on-click = "power-menu";
        };

        cpu = {
          interval = 2;
          format = "󰍛 {usage}%";
          tooltip = false;
        };

        memory = {
          interval = 2;
          format = "󰾆 {percentage}%";
          tooltip = false;
        };
      };
    };
  };
}
