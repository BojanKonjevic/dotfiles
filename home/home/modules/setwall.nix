{pkgs, theme, ...}: {
  home.packages = with pkgs; [
    (writeShellScriptBin "wallpaper-picker" ''
      WALLPAPER_DIR="$HOME/Pictures/wallpapers"
      LOCK_LINK="$WALLPAPER_DIR/wall.jpg"

      # Ensure swww-daemon is running
      if ! pgrep -x swww-daemon > /dev/null; then
        swww-daemon &
        sleep 0.5
      fi

      selected=$(
        find "$WALLPAPER_DIR" -maxdepth 1 -type f \
          \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
             -o -iname "*.webp" -o -iname "*.gif" \) \
        | sort \
        | while read -r img; do
            name="$(basename "$img")"
            printf '%s\0icon\x1f%s\n' "$name" "$img"
          done \
        | rofi -dmenu -i \
            -p "  Wallpaper" \
            -show-icons \
            -theme $HOME/.config/rofi/wallpaper.rasi
      )

      [[ -z "$selected" ]] && exit 0

      path="$WALLPAPER_DIR/$selected"
      [[ -f "$path" ]] || exit 1

      swww img "$path" \
        --transition-type wipe \
        --transition-angle 30 \
        --transition-duration 0.8 \
        --transition-fps 60

      ln -sf "$path" "$LOCK_LINK"
    '')
  ];

  xdg.configFile."rofi/wallpaper.rasi".text = ''
    * {
        font:             "JetBrainsMono Nerd Font 13";
        background-color: transparent;
        text-color:       ${theme.text};
    }

    window {
        width:            880px;
        background-color: rgba(${theme.crustRgb}, 0.93);
        border:       1px;
        border-color: rgba(${theme.surface1Rgb}, 0.45);
        border-radius:    14px;
        padding:          0;
    }

    mainbox {
        padding:          20px 14px 14px 14px;
        background-color: transparent;
        children:         [ inputbar, listview ];
        spacing:          14px;
    }

    /* underline search — lavender accent (distinct from clipboard green) */
    inputbar {
        background-color: transparent;
        border:           0 0 2px 0;
        border-color:     rgba(${theme.surface1Rgb}, 0.50);
        border-radius:    0;
        padding:          0 0 10px 0;
        spacing:          8px;
        children:         [ prompt, entry ];
    }

    prompt {
        text-color:     ${theme.lavender};
        font:           "JetBrainsMono Nerd Font Light 18";
        vertical-align: 0.5;
    }

    entry {
        text-color:        ${theme.text};
        placeholder:       "filter wallpapers…";
        placeholder-color: ${theme.overlay0};
        font:              "JetBrainsMono Nerd Font Light 18";
        vertical-align:    0.5;
    }

    listview {
        background-color: transparent;
        scrollbar:        false;
        lines:            3;
        columns:          3;
        spacing:          10px;
        fixed-height:     true;
    }

    element {
        orientation:      vertical;
        padding:          10px;
        border-radius:    10px;
        background-color: rgba(${theme.surface0Rgb}, 0.50);
        border:       1px;
        border-color: rgba(${theme.surface1Rgb}, 0.31);
        spacing:          8px;
    }

    element-icon {
        size:             160px;
        border-radius:    6px;
        horizontal-align: 0.5;
    }

    element-text {
        vertical-align:   0.5;
        horizontal-align: 0.5;
        text-color:       ${theme.subtext0};
        highlight:        bold ${theme.lavender};
        font:             "JetBrainsMono Nerd Font 11";
    }

    /* glow ring on hover/select — lavender */
    element selected {
        background-color: rgba(${theme.lavenderRgb}, 0.15);
        border:       1px;
        border-color: rgba(${theme.lavenderRgb}, 0.44);
        border-radius:    10px;
    }

    element selected element-text {
        text-color: ${theme.lavender};
        font:       "JetBrainsMono Nerd Font Bold 11";
    }
  '';
}
