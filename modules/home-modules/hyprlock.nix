{...}: {
  flake.homeModules.hyprlock = {
    userConfig,
    theme,
    lib,
    ...
  }: let
    hex = s: builtins.substring 1 6 s;
  in {
    programs.hyprlock = {
      enable = true;
      settings = lib.mkForce {
        general = {
          hide_cursor = true;
          ignore_empty_input = true;
          grace = 2;
        };

        animations = {
          enabled = true;
          fade_in = {
            duration = 400;
            bezier = "easeOutQuint";
          };
          fade_out = {
            duration = 250;
            bezier = "easeOutQuint";
          };
        };

        background = [
          {
            path = "${userConfig.wallpaperDir}/wall.jpg";
            blur_passes = 3;
            blur_size = 5;
            brightness = 0.6;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "280, 48";
            outline_thickness = 2;
            dots_size = 0.25;
            dots_spacing = 0.35;
            dots_center = true;
            outer_color = "rgb(${hex theme.surface1})";
            inner_color = "rgb(${hex theme.base})";
            font_color = "rgb(${hex theme.text})";
            fade_on_empty = true;
            placeholder_text = "<span foreground=\"##${hex theme.overlay1}\">󰌾  password</span>";
            check_color = "rgb(${hex theme.green})";
            fail_color = "rgb(${hex theme.red})";
            fail_text = "<i>$FAIL</i>";
            capslock_color = "rgb(${hex theme.peach})";
            position = "0, -120";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          {
            monitor = "";
            text = "cmd[update:1000] echo \"$(date +\"%H:%M\")\"";
            color = "rgb(${hex theme.mauve})";
            font_size = 86;
            font_family = "JetBrainsMono Nerd Font Black";
            position = "0, 60";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "cmd[update:60000] echo \"$(date +\"%A, %B %d\")\"";
            color = "rgb(${hex theme.subtext1})";
            font_size = 18;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, -30";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
