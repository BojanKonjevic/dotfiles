{pkgs, ...}: {
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
            -theme ~/.config/rofi/wallpaper.rasi
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
        base:      #1e1e2e;
        mantle:    #181825;
        surface0:  #313244;
        surface1:  #45475a;
        overlay0:  #6c7086;
        text:      #cdd6f4;
        green:     #a6e3a1;   /* teal/green accent – distinct from text sapphire */

        font:             "JetBrainsMono Nerd Font 13";
        background-color: transparent;
        text-color:       @text;
        border-color:     @green;
    }

    window {
        width:            860px;
        background-color: @mantle;
        border:           2px;
        border-color:     @green;
        border-radius:    14px;
        padding:          0;
    }

    mainbox {
        padding:          16px;
        background-color: transparent;
        children:         [ inputbar, listview ];
        spacing:          12px;
    }

    inputbar {
        background-color: @surface0;
        border-radius:    10px;
        border:           1px;
        border-color:     @surface1;
        padding:          8px 14px;
        spacing:          8px;
        children:         [ prompt, entry ];
    }

    prompt {
        text-color:        @green;
        font:              "JetBrainsMono Nerd Font Bold 13";
    }

    entry {
        text-color:        @text;
        placeholder:       "Filter images…";
        placeholder-color: @overlay0;
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
        background-color: @surface0;
        spacing:          8px;
    }

    /* Large square thumbnail */
    element-icon {
        size:             160px;
        border-radius:    8px;
        horizontal-align: 0.5;
    }

    element-text {
        vertical-align:   0.5;
        horizontal-align: 0.5;
        color:            @text;
        highlight:        bold #a6e3a1;
        font:             "JetBrainsMono Nerd Font 11";
    }

    element selected {
        background-color: #a6e3a126;
        border:           1px;
        border-color:     #a6e3a170;
    }
  '';
}
