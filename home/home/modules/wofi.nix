{...}: {
  programs.wofi = {
    enable = true;

    settings = {
      width = 480;
      height = 360;
      location = "center";
      show = "drun";
      prompt = "Launch";
      allow_markup = true;
      no_actions = true;
      insensitive = true;
      allow_images = true;
      image_size = 24;
      icon_theme = "Papirus";
      filter_rate = 120;
      parse_search = true;
      hide_scroll = true;
      term = "kitty";
    };

    style = ''
      /* ────────────────────────────────────────────────
         Catppuccin Mocha - Wofi
         (with mauve/lavender accent)
      ──────────────────────────────────────────────── */

      @define-color base      #1e1e2e;
      @define-color mantle   #181825;
      @define-color crust    #11111b;

      @define-color text     #cdd6f4;
      @define-color subtext0 #a6adc8;
      @define-color subtext1 #bac2de;

      @define-color surface0 #313244;
      @define-color surface1 #45475a;
      @define-color surface2 #585b70;

      @define-color overlay0 #6c7086;
      @define-color overlay1 #7f849c;
      @define-color overlay2 #9399b2;

      @define-color mauve    #cba6f7;   /* accent */
      @define-color lavender #b4befe;
      @define-color sapphire #74c7ec;
      @define-color pink     #f5c2e7;

      * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size:   17px;          /* bit smaller but crisp */
        font-weight: 900;           /* semi-bold instead of black */
      }

      window {
        margin: 0px;
        border: 2px solid @mauve;
        border-radius: 14px;
        background-color: alpha(@mantle, 0.94);
        font-family: inherit;
      }

      #input {
        margin: 12px 16px 8px 16px;
        padding: 10px 14px;
        border-radius: 10px;
        border: 1px solid @surface1;
        background-color: alpha(@surface0, 0.75);
        color: @text;
        caret-color: @mauve;
        box-shadow: inset 0 1px 2px rgba(0,0,0,0.15);
      }

      #input image { color: @overlay0; }

      #input:focus {
        border-color: @mauve;
        background-color: alpha(@surface1, 0.6);
        box-shadow: 0 0 0 2px alpha(@mauve, 0.35);
      }

      #inner-box {
        margin: 0 8px 12px 8px;
        background-color: transparent;
      }

      #outer-box {
        margin: 0px;
        background-color: transparent;
      }

      #scroll {
        margin: 4px 0;
      }

      #entry {
        padding: 10px 16px;
        margin: 3px 6px;
        border-radius: 9px;
        color: @text;
        background-color: transparent;
        transition: all 120ms ease-out;
      }

      #entry:selected {
        background-color: alpha(@mauve, 0.18);
        border: 1px solid alpha(@mauve, 0.35);
        box-shadow: 0 0 12px alpha(@mauve, 0.12);
      }

      #entry image {
        margin-right: 12px;
        color: @mauve;
      }

      #text {
        color: inherit;
      }

      /* subtle row appearance animation */
      #entry {
        opacity: 0.92;
        transform: translateY(4px);
        animation: appear 0.18s forwards;
      }

      @keyframes appear {
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
    '';
  };
}
