{...}: {
  programs.wofi = {
    enable = true;

    settings = {
      width = 580;
      height = 400;
      location = "center";
      show = "drun";
      prompt = "run something";
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
         Catppuccin Mocha — command palette, frosted glass
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

      * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size:   14px;
        font-weight: 400;
        outline:     none;
      }

      /* ── Window ─────────────────────────────────────────────────────────── */
      window {
        margin:        0px;
        border-radius: 14px;
        border:        1px solid alpha(@surface1, 0.45);
        background:    linear-gradient(
                         to bottom,
                         alpha(@mauve, 0.08) 0px,
                         transparent 56px
                       ),
                       alpha(@crust, 0.93);
        box-shadow:    0 24px 60px rgba(0,0,0,0.50),
                       0 0 0 1px alpha(@crust, 0.40),
                       inset 0 1px 0 alpha(@mauve, 0.10);
      }

      /* ── Search bar — underline style ───────────────────────────────────── */
      #input {
        margin:           20px 24px 0 24px;
        padding:          4px 0 10px 0;
        border-radius:    0;
        border:           none;
        border-bottom:    2px solid alpha(@surface1, 0.80);
        background-color: transparent;
        color:            @text;
        caret-color:      @mauve;
        font-size:        18px;
        font-weight:      300;
        letter-spacing:   0.02em;
        box-shadow:       none;
      }

      #input image {
        color:        @overlay0;
        margin-right: 10px;
      }

      #input:focus {
        border-bottom-color: @mauve;
      }

      /* ── Layout ─────────────────────────────────────────────────────────── */
      #outer-box {
        margin:     0px;
        background: transparent;
      }

      #inner-box {
        margin:     10px;
        padding-top: 6px;
        background: transparent;
      }

      #scroll {
        margin: 0;
      }

      /* ── Scrollbar ──────────────────────────────────────────────────────── */
      scrollbar {
        background: transparent;
        border:     none;
      }

      scrollbar slider {
        min-width:        3px;
        background-color: alpha(@surface2, 0.40);
        border-radius:    3px;
        margin:           3px;
      }

      scrollbar slider:hover {
        background-color: alpha(@mauve, 0.50);
      }

      /* ── Entries ────────────────────────────────────────────────────────── */
      #entry {
        padding:    9px 14px;
        margin:     1px 0;
        border-radius: 8px;
        border:     1px solid transparent;
        color:      @subtext0;
        background: transparent;
        transition: background 100ms ease,
                    color 100ms ease,
                    border-color 100ms ease;
      }

      #entry:hover {
        background: alpha(@surface0, 0.45);
        border-color: alpha(@surface1, 0.40);
        color: @text;
      }

      /* inverted selection */
      #entry:selected {
        background: @mauve;
        border-color: alpha(@lavender, 0.30);
        color: @crust;
        box-shadow: 0 2px 14px alpha(@mauve, 0.30);
      }

      /* ── Icons ──────────────────────────────────────────────────────────── */
      #entry image {
        margin-right: 12px;
        color:        @overlay0;
      }

      #entry:hover image {
        color: @subtext1;
      }

      #entry:selected image {
        color: @crust;
      }

      /* ── Text ───────────────────────────────────────────────────────────── */
      #text {
        color: inherit;
      }

      #entry:selected #text {
        color:       @crust;
        font-weight: 600;
      }
    '';
  };
}
