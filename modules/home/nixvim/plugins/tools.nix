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

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>fr";
      action = "<cmd>GrugFar<CR>";
      options.desc = "[F]ind and [R]eplace";
    }
    {
      mode = "n";
      key = "<leader>fw";
      action = "<cmd>lua require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })<CR>";
      options.desc = "[F]ind and Replace [W]ord";
    }
    {
      mode = "v";
      key = "<leader>fr";
      action = "<cmd>lua require('grug-far').with_visual_selection()<CR>";
      options.desc = "[F]ind and [R]eplace selection";
    }

    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<CR>";
      options.desc = "Diagnostics (project)";
    }
    {
      mode = "n";
      key = "<leader>xb";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
      options.desc = "Diagnostics (buffer)";
    }
    {
      mode = "n";
      key = "<leader>xs";
      action = "<cmd>Trouble symbols toggle<CR>";
      options.desc = "Symbols";
    }
    {
      mode = "n";
      key = "<leader>xq";
      action = "<cmd>Trouble qflist toggle<CR>";
      options.desc = "Quickfix list";
    }

    {
      mode = "n";
      key = "<leader>u";
      action = "<cmd>UndotreeToggle<CR>";
      options.desc = "[U]ndo tree";
    }

    {
      mode = ["n" "i"];
      key = "<ScrollWheelUp>";
      action.__raw = "function() require('neoscroll').scroll(-5, { duration = 80, easing = 'quadratic' }) end";
    }
    {
      mode = ["n" "i"];
      key = "<ScrollWheelDown>";
      action.__raw = "function() require('neoscroll').scroll(5, { duration = 80, easing = 'quadratic' }) end";
    }

    {
      mode = "n";
      key = "<leader>r";
      action.__raw = ''
        function()
          local file = vim.fn.expand("%:p")
          local term = require("toggleterm.terminal").Terminal:new({
            cmd = "python3 " .. vim.fn.shellescape(file),
            direction = "float",
            float_opts = {
              border = "rounded",
              width = math.floor(vim.o.columns * 0.92),
              height = math.floor(vim.o.lines * 0.82),
            },
            close_on_exit = false,
            auto_scroll = true,
          })
          term:toggle()
        end
      '';
      options.desc = "[R]un Python file";
    }
  ];
}
