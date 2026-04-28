{...}: {
  programs.nixvim.keymaps = [
    # ── Harpoon ───────────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<C-a>";
      action.__raw = "function() require('harpoon'):list():add() end";
      options.desc = "Harpoon add file";
    }
    {
      mode = "n";
      key = "<C-e>";
      action.__raw = "function() local h = require('harpoon') h.ui:toggle_quick_menu(h:list()) end";
      options.desc = "Harpoon menu";
    }
    {
      mode = "n";
      key = "<C-1>";
      action.__raw = "function() require('harpoon'):list():select(1) end";
      options.desc = "Harpoon file 1";
    }
    {
      mode = "n";
      key = "<C-2>";
      action.__raw = "function() require('harpoon'):list():select(2) end";
      options.desc = "Harpoon file 2";
    }
    {
      mode = "n";
      key = "<C-3>";
      action.__raw = "function() require('harpoon'):list():select(3) end";
      options.desc = "Harpoon file 3";
    }
    {
      mode = "n";
      key = "<C-4>";
      action.__raw = "function() require('harpoon'):list():select(4) end";
      options.desc = "Harpoon file 4";
    }

    # ── Grug-far ──────────────────────────────────────────────────────────────
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

    # ── Lazygit ───────────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<C-g>";
      action = "<cmd>LazyGit<CR>";
      options.desc = "Toggle Lazygit";
    }

    # ── Diffview ──────────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>gd";
      action = "<cmd>DiffviewOpen<CR>";
      options.desc = "[G]it [D]iff working tree";
    }
    {
      mode = "n";
      key = "<leader>gD";
      action = "<cmd>DiffviewOpen HEAD~1<CR>";
      options.desc = "[G]it [D]iff last commit";
    }
    {
      mode = "n";
      key = "<leader>gh";
      action = "<cmd>DiffviewFileHistory %<CR>";
      options.desc = "[G]it file [H]istory";
    }
    {
      mode = "n";
      key = "<leader>gH";
      action = "<cmd>DiffviewFileHistory<CR>";
      options.desc = "[G]it repo [H]istory";
    }
    {
      mode = "n";
      key = "<leader>gc";
      action = "<cmd>DiffviewClose<CR>";
      options.desc = "[G]it [C]lose diff";
    }

    # ── Trouble ───────────────────────────────────────────────────────────────
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

    # ── Flash ─────────────────────────────────────────────────────────────────
    {
      mode = ["n" "x" "o"];
      key = "f";
      action.__raw = "function() require('flash').jump() end";
      options.desc = "Flash";
    }
    {
      mode = ["n" "x" "o"];
      key = "S";
      action.__raw = "function() require('flash').treesitter() end";
      options.desc = "Flash Treesitter";
    }
    {
      mode = "o";
      key = "r";
      action.__raw = "function() require('flash').remote() end";
      options.desc = "Remote Flash";
    }

    # ── Oil ───────────────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "\\";
      action = "<cmd>Oil<CR>";
      options.desc = "Open parent directory";
    }

    # ── Neoscroll (scroll wheel) ──────────────────────────────────────────────
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

    # ── Python runner ─────────────────────────────────────────────────────────
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

    # ── Blink (Tab with explicit tab fallback) ────────────────────────────────
    {
      mode = "i";
      key = "<Tab>";
      action.__raw = ''
        function()
          local blink = require("blink.cmp")
          if blink.is_visible() then
            blink.accept()
          else
            return "\t"
          end
        end
      '';
      options = {
        expr = true;
        silent = true;
        noremap = true;
        desc = "blink accept";
      };
    }

    # ── Window navigation ─────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w><C-h>";
      options.desc = "Move focus left";
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w><C-l>";
      options.desc = "Move focus right";
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w><C-j>";
      options.desc = "Move focus down";
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w><C-k>";
      options.desc = "Move focus up";
    }

    # ── Editor ────────────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<C-s>";
      action = ":w<CR>";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      mode = "i";
      key = "<C-s>";
      action = "<Esc>:w<CR>a";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-q>";
      action = ":qa<CR>";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<Esc>";
      action = "<cmd>nohlsearch<CR>";
    }
    {
      mode = "n";
      key = "<leader>u";
      action = "<cmd>UndotreeToggle<CR>";
      options.desc = "[U]ndo tree";
    }

    # ── Leetcode ──────────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>t";
      action = "<cmd>Leet test<CR>";
      options.desc = "Leet test";
    }
    {
      mode = "n";
      key = "<leader>ls";
      action = "<cmd>Leet submit<CR>";
      options.desc = "Leet submit";
    }
  ];
}
