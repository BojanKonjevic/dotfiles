{...}: {
  flake.homeModules.hyprland = {
    userConfig,
    theme,
    lib,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      grim
      slurp
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;

      settings = {
        "$mainMod" = "SUPER";
        "$terminal" = "kitty";
        "$fileManager" = "thunar";
        "$menu" = "qs -c launcher";
        "$privateWindow" = "zen-beta --no-remote --private-window";

        windowrule = [
          "opacity 0.95 override 0.92 override, match:class ^(vesktop)$"
          "opacity 0.95 override 0.92 override, match:class ^(localsend_app)$"
          "opacity 0.95 override 0.92 override, match:class ^(thunar)$"
          "opacity 0.95 override 0.92 override, match:class ^(xarchiver)$"
          "opacity 0.95 override 0.92 override, match:class ^(zen-beta)$"
          "opacity 0.93 override 0.90 override, match:class ^(org.qbittorrent.qBittorrent)$"
          "opacity 0.90 override 0.87 override, match:class ^(kitty)$"
          "opacity 0.93 override 0.90 override, match:class ^(nm-connection-editor)$"
          "float 1, match:class ^(media-popup)$"
          "center 1, match:class ^(media-popup)$"
          "border_size 0, match:class ^(media-popup)$"
        ];

        env = [
          "XCURSOR_THEME,${theme.cursorTheme}"
          "XCURSOR_SIZE,${theme.cursorSize}"
          "HYPRCURSOR_THEME,${theme.cursorTheme}"
          "HYPRCURSOR_SIZE,${theme.cursorSize}"
        ];

        exec-once = [
          "qs -c bar"
          "awww-daemon"
          "hyprlock || hyprctl dispatch exit"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
        ];

        monitor = [",preferred,auto,auto"];

        input = {
          kb_layout = userConfig.kbLayout;
          follow_mouse = 1;
          sensitivity = 0;
          repeat_delay = 200;
          repeat_rate = 35;
        };

        cursor = {
          inactive_timeout = 2;
        };

        general = {
          gaps_in = 3;
          gaps_out = 5;
          border_size = 2;
          "col.active_border" = "$mauve $blue 45deg";
          "col.inactive_border" = "$surface1";
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
          rounding = 10;
          rounding_power = 2;
          active_opacity = 1.0;

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };

        animations = {
          enabled = true;

          bezier = [
            "myEase, 0.05, 0.9, 0.1, 1.05"
            "smoothOut, 0.22, 1.0, 0.36, 1.0"
            "linearFade, 0.3, 0.0, 0.7, 1.0"
            "quickEase, 0.25, 0.1, 0.25, 1.0"
          ];

          animation = [
            "global, 9, 8, smoothOut"
            "border, 1, 12, default"
            "windows, 1, 6, myEase"
            "windowsIn, 1, 5.5, myEase, popin 82%"
            "windowsOut, 1, 3.2, linear, popin 76%"
            "windowsMove, 1, 5, smoothOut"
            "fade, 1, 3.5, linearFade"
            "fadeIn, 1, 2.5, linearFade"
            "fadeOut, 1, 2.0, linearFade"
            "layers, 1, 7, smoothOut"
            "layersIn, 1, 6, smoothOut, fade"
            "layersOut, 1, 3, quickEase, fade"
            "workspaces, 1, 5.5, myEase, slidefadevert 15%"
            "workspacesIn, 1, 4.8, myEase, slidefadevert 15%"
            "workspacesOut, 1, 5.5, myEase, slidefadevert 15%"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };

        misc = {
          vfr = true;
          force_default_wallpaper = 0;
          disable_hyprland_logo = false;
        };

        bind =
          [
            "CTRL, ESCAPE, exec, ydotool click 0xC0"
            "$mainMod SHIFT, W, exec, wallpaper-picker"
            "$mainMod, BACKSLASH, exec, mic-toggle"
            "$mainMod, M, exec, media-popup-toggle"
            "$mainMod, N, exec, $privateWindow"
            "$mainMod, C, exec, qs -c clip-text"
            "$mainMod SHIFT, C, exec, qs -c clip-img"

            "$mainMod, S, exec, grim -g \"$(slurp)\" - | wl-copy"
            "$mainMod SHIFT, S, exec, wl-paste --type image/png > \"${userConfig.screenshotsDir}/shot_$(date +%F_%H-%M-%S).png\""

            "$mainMod, RETURN, exec, $terminal"
            "$mainMod, e, exec, $fileManager"
            "$mainMod, Q, killactive"
            "$mainMod, V, togglefloating"
            "$mainMod, SPACE, exec, $menu"

            "$mainMod, h, movefocus, l"
            "$mainMod, l, movefocus, r"
            "$mainMod, k, movefocus, u"
            "$mainMod, j, movefocus, d"

            "$mainMod SHIFT, h, movewindow, l"
            "$mainMod SHIFT, l, movewindow, r"
            "$mainMod SHIFT, k, movewindow, u"
            "$mainMod SHIFT, j, movewindow, d"
          ]
          ++ (map (n: "$mainMod, ${toString n}, workspace, ${toString n}") (lib.range 1 9))
          ++ ["$mainMod, 0, workspace, 10"]
          ++ (map (n: "$mainMod SHIFT, ${toString n}, movetoworkspace, ${toString n}") (lib.range 1 9))
          ++ ["$mainMod SHIFT, 0, movetoworkspace, 10"];

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];
      };
      extraConfig = ''
        bind = $mainMod, R, submap, resize
        submap = resize
          binde = , H, resizeactive, -20 0
          binde = , L, resizeactive, 20 0
          binde = , K, resizeactive, 0 -20
          binde = , J, resizeactive, 0 20

          bind = , RETURN, submap, reset
          bind = , ESCAPE, submap, reset
        submap = reset
      '';
    };
  };
}
