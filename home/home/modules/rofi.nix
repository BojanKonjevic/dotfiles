{pkgs, theme, ...}: {
  programs.rofi = {
    enable = true;
  };

  xdg.configFile."rofi/launcher.rasi".text = ''
    /*  Catppuccin Mocha — command palette, frosted glass  */

    * {
        font:             "JetBrainsMono Nerd Font 14";
        background-color: transparent;
        text-color:       ${theme.text};
    }

    window {
        width:            580px;
        height:           400px;
        border-radius:    14px;
        border:           1px;
        border-color:     rgba(${theme.surface1Rgb}, 0.45);
        background-color: rgba(${theme.crustRgb}, 0.93);
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
        border-color:     rgba(${theme.surface1Rgb}, 0.50);
        padding:          0 0 10px 0;
        spacing:          8px;
        children:         [prompt, entry];
    }

    prompt {
        background-color: transparent;
        text-color:       ${theme.mauve};
        font:             "JetBrainsMono Nerd Font Bold 18";
        vertical-align:   0.5;
    }

    entry {
        background-color:  transparent;
        text-color:        ${theme.text};
        placeholder-color: ${theme.overlay0};
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
        text-color:       ${theme.subtext0};
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
        text-color:       ${theme.subtext0};
    }

    /* ── Hover (rofi has no separate hover; selected covers it) ───────── */

    /* ── Selected — inverted, mauve ──────────────────────────────────── */

    element selected.normal {
        background-color: rgba(${theme.mauveRgb}, 0.25);
        border:           1px;
        border-color:     rgba(${theme.mauveRgb}, 0.60);
        text-color:       ${theme.mauve};
    }

  '';
}
