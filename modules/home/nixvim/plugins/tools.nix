{...}: {
  programs.nixvim.plugins = {
    mini = {
      enable = true;
      modules = {
        ai.n_lines = 500;
        comment = {};
        surround = {};
        pairs = {};
        move = {};
      };
    };

    grug-far = {
      enable = true;
      settings = {
        headerMaxWidth = 80;
        resultsSeparatorLineChar = "─";
        spinnerStates = ["⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷"];
        keymaps = {
          replace = {n = "<leader>r";};
          qflist = {n = "<leader>q";};
          syncLocations = {n = "<leader>s";};
          syncLine = {n = "<leader>l";};
          close = {n = "q";};
          historyOpen = {n = "<leader>h";};
          historyAdd = {n = "<leader>H";};
          refresh = {n = "<leader>R";};
          gotoLocation = {n = "<enter>";};
          pickHistoryEntry = {n = "<enter>";};
          abort = {n = "<leader>a";};
          toggleShowRgsInfo = {n = "<leader>i";};
          openLocation = {n = "<leader>o";};
        };
        engines.ripgrep.extraArgs = "--smart-case";
      };
    };

    trouble.enable = true;

    undotree.enable = true;

    neoscroll = {
      enable = true;
      settings = {
        mappings = [];
        hide_cursor = true;
        stop_eof = true;
        respect_scrolloff = true;
        cursor_scrolls_alone = false;
        duration_multiplier = 0.8;
        easing = "cubic";
      };
    };

    toggleterm = {
      enable = true;
      settings = {
        size = 15;
        open_mapping = "[[<c-\\>]]";
        direction = "horizontal";
        shade_terminals = false;
        persist_size = true;
        close_on_exit = false;
      };
    };

    guess-indent.enable = true;
  };
}
