{
  pkgs,
  theme,
  ...
}: {
  home.packages = with pkgs; [
    wl-clipboard
    cliphist
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
        font:             "JetBrainsMono Nerd Font 13";
        background-color: transparent;
        text-color:       ${theme.text};
    }

    window {
        width:            640px;
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

    /* underline-style search bar */
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
        text-color:     ${theme.sapphire};
        font:           "JetBrainsMono Nerd Font Light 18";
        vertical-align: 0.5;
    }

    entry {
        text-color:        ${theme.text};
        placeholder:       "search clipboard…";
        placeholder-color: ${theme.overlay0};
        font:              "JetBrainsMono Nerd Font Light 18";
        vertical-align:    0.5;
    }

    listview {
        background-color: transparent;
        scrollbar:        false;
        lines:            7;
        columns:          1;
        spacing:          3px;
        fixed-height:     true;
    }

    element {
        orientation:      horizontal;
        padding:          9px 14px;
        border-radius:    8px;
        background-color: transparent;
        border:       1px;
        border-color: transparent;
        spacing:          10px;
    }

    element-text {
        vertical-align: 0.5;
        text-color:     ${theme.subtext0};
        highlight:      bold ${theme.sapphire};
    }

    element selected {
        background-color: rgba(${theme.sapphireRgb}, 0.18);
        border:       1px;
        border-color: rgba(${theme.sapphireRgb}, 0.55);
        border-radius:    8px;
    }

    element selected element-text {
        text-color: ${theme.sapphire};
        highlight:  bold ${theme.sky};
        font:       "JetBrainsMono Nerd Font 13";
    }
  '';

  xdg.configFile."rofi/clipboard-img.rasi".text = ''
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

    inputbar {
        background-color: transparent;
        border:           0 0 2px 0;
        border-color:     rgba(${theme.surface1Rgb}, 0.50);
        border-radius:    0;
        padding:          0 0 10px 0;
        spacing:          0;
        children:         [ prompt ];
    }

    prompt {
        text-color:     ${theme.green};
        font:           "JetBrainsMono Nerd Font Light 18";
        vertical-align: 0.5;
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
        width:  0;
        height: 0;
        color:  transparent;
    }

    element selected {
        background-color: rgba(${theme.greenRgb}, 0.15);
        border:       1px;
        border-color: rgba(${theme.greenRgb}, 0.44);
        border-radius:    10px;
    }

    element selected element-text {
        text-color: transparent;
    }
  '';
}
