{...}: {
  programs.wofi = {
    enable = true;

    settings = {
      width = 500;
      height = 420;
      location = "center";
      show = "drun";
      prompt = "Launch";
      allow_markup = true;
      no_actions = true;
      insensitive = true;
      allow_images = true;
      image_size = 28;
      icon_theme = "Papirus";
      filter_rate = 120;
      parse_search = true;
      hide_scroll = true;
      term = "kitty";
      exec-search = true;
      display_generic = false;
      columns = 1;
    };

    style = ''
      /* ────────────────────────────────────────────────
         Catppuccin Mocha - Wofi launcher
         (mauve/lavender accent)
      ──────────────────────────────────────────────── */

      @define-color base      #1e1e2e;
      @define-color mantle    #181825;
      @define-color crust     #11111b;

      @define-color text      #cdd6f4;
      @define-color subtext0  #a6adc8;
      @define-color subtext1  #bac2de;

      @define-color surface0  #313244;
      @define-color surface1  #45475a;
      @define-color surface2  #585b70;

      @define-color overlay0  #6c7086;
      @define-color overlay1  #7f849c;

      @define-color mauve     #cba6f7;
      @define-color lavender  #b4befe;
      @define-color sapphire  #74c7ec;

      * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size:   15px;
        font-weight: 600;
      }

      window {
        margin:           0px;
        border:           2px solid @mauve;
        border-radius:    16px;
        background-color: alpha(@mantle, 0.96);
      }

      /* ── Search bar ─────────────────────────────────────────────────────── */
      #input {
        margin:           14px 14px 0 14px;
        padding:          10px 14px;
        border-radius:    12px;
        border:           1px solid @surface1;
        background-color: alpha(@surface0, 0.80);
        color:            @text;
        caret-color:      @mauve;
        box-shadow:       inset 0 1px 3px rgba(0,0,0,0.20);
      }

      #input image { color: @overlay0; }

      #input:focus {
        border-color:     @mauve;
        background-color: alpha(@surface1, 0.65);
        box-shadow:       0 0 0 2px alpha(@mauve, 0.30);
      }

      /* ── Subtle divider between search and list ─────────────────────────── */
      #outer-box {
        margin:           0px;
        background-color: transparent;
      }

      #inner-box {
        margin:           8px 8px 12px 8px;
        padding-top:      6px;
        border-top:       1px solid @surface1;
        background-color: transparent;
      }

      #scroll {
        margin: 2px 0;
      }

      /* ── App entries ────────────────────────────────────────────────────── */
      #entry {
        padding:          9px 14px;
        margin:           2px 4px;
        border-radius:    10px;
        color:            @text;
        background-color: transparent;
        transition:       background 100ms ease-out,
                          border 100ms ease-out,
                          box-shadow 100ms ease-out;
      }

      #entry:selected {
        background-color: alpha(@mauve, 0.16);
        border:           1px solid alpha(@mauve, 0.40);
        box-shadow:       0 0 14px alpha(@mauve, 0.14),
                          inset 0 1px 0 alpha(@mauve, 0.08);
      }

      /* Icon colour tint */
      #entry image {
        margin-right: 12px;
        color:        @mauve;
      }

      #entry:selected image {
        color: @lavender;
      }

      #text {
        color: inherit;
      }

      #entry:selected #text {
        color: @lavender;
      }
    '';
  };
}
