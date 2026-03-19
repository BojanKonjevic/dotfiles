{pkgs, ...}: {
  programs.rofi = {
    enable = true;
  };

  xdg.configFile."rofi/launcher.rasi".text = ''
    /*  Catppuccin Mocha — command palette, frosted glass  */

    * {
        font:             "JetBrainsMono Nerd Font 14";
        background-color: transparent;
        text-color:       #cdd6f4;
    }

    window {
        width:            580px;
        height:           400px;
        border-radius:    14px;
        border:           1px;
        border-color:     rgba(69, 71, 90, 0.45);
        background-color: rgba(17, 17, 27, 0.93);
        padding:          0;
    }

    mainbox {
        background-color: transparent;
        padding:          20px 14px 14px 14px;
        spacing:          14px;
        children:         [inputbar, listview];
    }

    /* ── Search bar — underline style ─────────────────────────────────── */
    inputbar {
        background-color: transparent;
        border:           0 0 2px 0;
        border-color:     rgba(69, 71, 90, 0.50);
        padding:          0 0 10px 0;
        spacing:          8px;
        children:         [prompt, entry];
    }

    prompt {
        background-color: transparent;
        text-color:       #cba6f7;
        font:             "JetBrainsMono Nerd Font Bold 18";
        vertical-align:   0.5;
    }

    entry {
        background-color:  transparent;
        text-color:        #cdd6f4;
        placeholder-color: #6c7086;
        font:              "JetBrainsMono Nerd Font Light 18";
        vertical-align:    0.5;
        cursor:            text;
    }

    /* ── Results list ─────────────────────────────────────────────────── */
    listview {
        background-color: transparent;
        scrollbar:        false;
        lines:            8;
        columns:          1;
        spacing:          1px;
        fixed-height:     true;
        padding:          6px 0 0 0;
    }

    element {
        padding:          9px 14px;
        border-radius:    8px;
        border:       1px;
        border-color: transparent;
        background-color: transparent;
        text-color:       #a6adc8;
        spacing:          12px;
        orientation:      horizontal;
    }

    element-icon {
        size:             28px;
        vertical-align:   0.5;
        background-color: transparent;
    }

    element-text {
        vertical-align:   0.5;
        background-color: transparent;
    }

    /* ── Normal / alternate rows ──────────────────────────────────────── */
    element normal.normal,
    element alternate.normal {
        background-color: transparent;
        text-color:       #a6adc8;
    }

    /* ── Hover (rofi has no separate hover; selected covers it) ───────── */

    /* ── Selected — inverted, mauve ──────────────────────────────────── */

    element selected.normal {
        background-color: rgba(203, 166, 247, 0.25);
        border:           1px;
        border-color:     rgba(203, 166, 247, 0.60);
        text-color:       #cba6f7;
    }

  '';
}
