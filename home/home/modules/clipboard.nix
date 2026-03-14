{pkgs, ...}: {
  home.packages = with pkgs; [
    rofi
    (writeShellScriptBin "clip-pick-text" ''
      cliphist list | while IFS=$'\t' read -r id content; do
        [[ "$content" == *"[[ binary data"* ]] && continue
        printf '%s\t%s\n' "$id" "$content"
      done
    '')
    (writeShellScriptBin "clip-pick-img" ''
      CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-rofi"
      mkdir -p "$CACHE_DIR"
      mapfile -t live_ids < <(cliphist list | awk -F'\t' '{print $1}')
      for f in "$CACHE_DIR"/*.png; do
        [[ -f "$f" ]] || continue
        id="''${f##*/}"; id="''${id%.png}"
        printf '%s\n' "''${live_ids[@]}" | grep -qx "$id" || rm -f "$f"
      done
      cliphist list | while IFS=$'\t' read -r id content; do
        [[ "$content" == *"[[ binary data"* ]] || continue
        img="$CACHE_DIR/''${id}.png"
        if [[ ! -s "$img" ]]; then
          cliphist decode <<< "''${id}"$'\t'"''${content}" > "$img" 2>/dev/null
        fi
        if [[ -s "$img" ]]; then
          printf '%s\t%s\0icon\x1f%s\n' "$id" "$content" "$img"
        fi
      done
    '')
  ];
  xdg.configFile."rofi/clipboard.rasi".text = ''
    * {
        base:      #1e1e2e;
        mantle:    #181825;
        surface0:  #313244;
        surface1:  #45475a;
        overlay0:  #6c7086;
        text:      #cdd6f4;
        sapphire:  #74c7ec;

        font:             "JetBrainsMono Nerd Font 13";
        background-color: transparent;
        text-color:       @text;
        border-color:     @sapphire;
    }

    window {
        width:            640px;
        background-color: @mantle;
        border:           2px;
        border-color:     @sapphire;
        border-radius:    14px;
        padding:          0;
    }

    mainbox {
        padding:          14px;
        background-color: transparent;
        children:         [ inputbar, listview ];
        spacing:          10px;
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
        text-color:        @sapphire;
        font:              "JetBrainsMono Nerd Font Bold 13";
    }

    entry {
        text-color:        @text;
        placeholder:       "Search text…";
        placeholder-color: @overlay0;
    }

    listview {
        background-color: transparent;
        scrollbar:        false;
        lines:            7;
        columns:          1;
        spacing:          4px;
        fixed-height:     true;
    }

    element {
        orientation:      horizontal;
        padding:          8px 12px;
        border-radius:    9px;
        background-color: transparent;
        spacing:          10px;
    }

    element-text {
        vertical-align:   0.5;
        color:            @text;
        highlight:        bold #74c7ec;
    }

    element selected {
        background-color: #74c7ec26;
        border:           1px;
        border-color:     #74c7ec70;
    }
  '';
  xdg.configFile."rofi/clipboard-img.rasi".text = ''
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
