{...}: {
  flake.homeModules.hyprlock = {
    userConfig,
    lib,
    ...
  }: {
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
            outer_color = "rgb(313244)";
            inner_color = "rgb(1e1e2e)";
            font_color = "rgb(cdd6f4)";
            fade_on_empty = true;
            placeholder_text = "<span foreground=\"##7f849c\">󰌾  password</span>";
            check_color = "rgb(a6e3a1)";
            fail_color = "rgb(f38ba8)";
            fail_text = "<i>$FAIL</i>";
            capslock_color = "rgb(fab387)";
            position = "0, -120";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          {
            monitor = "";
            text = "cmd[update:1000] echo \"$(date +\"%H:%M\")\"";
            color = "rgb(cba6f7)";
            font_size = 86;
            font_family = "JetBrainsMono Nerd Font Black";
            position = "0, 60";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "cmd[update:60000] echo \"$(date +\"%A, %B %d\")\"";
            color = "rgb(bac2de)";
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
