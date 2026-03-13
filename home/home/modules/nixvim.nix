{pkgs, ...}: {
  programs.nixvim = {
    enable = true;

    extraPackages = with pkgs; [
      alejandra
      stylua
      isort
    ];

    extraPlugins = with pkgs.vimPlugins; [
      tiny-inline-diagnostic-nvim
      flash-nvim
      guess-indent-nvim
      vim-visual-multi
      leetcode-nvim
      neo-tree-nvim
      neoscroll-nvim
    ];

    plugins = {
      web-devicons.enable = true;

      toggleterm = {
        enable = true;
        settings = {
          size = 15;
          open_mapping = "[[<c-\\>]]";
          direction = "horizontal";
          shade_terminals = false;
          persist_size = true;
          close_on_exit = false; # keeps output visible after script finishes
        };
      };

      treesitter = {
        enable = true;
        settings = {
          ensure_installed = [
            "bash"
            "diff"
            "html"
            "lua"
            "luadoc"
            "markdown"
            "markdown_inline"
            "query"
            "vim"
            "vimdoc"
            "css"
            "json"
            "python"
          ];
          auto_install = false;
          highlight.enable = true;
          indent.enable = true;
        };
      };

      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
          ui-select = {
            enable = true;
            settings.__raw = ''require("telescope.themes").get_dropdown()'';
          };
        };
        keymaps = {
          "<leader>sh" = {
            action = "help_tags";
            options.desc = "[S]earch [H]elp";
          };
          "<leader>sk" = {
            action = "keymaps";
            options.desc = "[S]earch [K]eymaps";
          };
          "<leader>sf" = {
            action = "find_files";
            options.desc = "[S]earch [F]iles";
          };
          "<leader>ss" = {
            action = "builtin";
            options.desc = "[S]earch [S]elect Telescope";
          };
          "<leader>sw" = {
            action = "grep_string";
            options.desc = "[S]earch current [W]ord";
          };
          "<leader>sg" = {
            action = "live_grep";
            options.desc = "[S]earch by [G]rep";
          };
          "<leader>sd" = {
            action = "diagnostics";
            options.desc = "[S]earch [D]iagnostics";
          };
          "<leader>sr" = {
            action = "resume";
            options.desc = "[S]earch [R]esume";
          };
          "<leader>s." = {
            action = "oldfiles";
            options.desc = "[S]earch Recent Files (\".\" for repeat)";
          };
          "<leader><leader>" = {
            action = "buffers";
            options.desc = "[ ] Find existing buffers";
          };
        };
      };

      gitsigns = {
        enable = true;
        settings.signs = {
          add.text = "+";
          change.text = "~";
          delete.text = "_";
          topdelete.text = "‾";
          changedelete.text = "~";
        };
      };

      which-key = {
        enable = true;
        settings = {
          delay = 0;
          icons.mappings = true;
          icons.keys = {};
          spec = [
            {
              __unkeyed-1 = "<leader>s";
              name = "[S]earch";
            }
          ];
        };
      };

      conform-nvim = {
        enable = true;
        settings = {
          notify_on_error = false;
          format_on_save.__raw = ''
            function(bufnr)
              return { timeout_ms = 500, lsp_format = "fallback" }
            end
          '';
          formatters_by_ft = {
            nix = ["alejandra"];
            lua = ["stylua"];
            python = ["ruff_format" "isort"];
          };
        };
      };

      blink-cmp = {
        enable = true;
        appearance.nerd_font_variant = "mono";
        completion = {
          documentation.auto_show = false;
          documentation.auto_show_delay_ms = 500;
          ghost_text.enabled = true;
          list.selection = "auto_insert";
        };
        sources = {
          default = ["lsp" "path" "snippets" "lazydev"];
          providers.lazydev = {
            module = "lazydev.integrations.blink";
            score_offset = 100;
          };
        };
        snippets.preset = "luasnip";
        fuzzy.implementation = "lua";
        signature.enabled = true;
      };

      lazydev = {
        enable = true;
        settings.library = [
          {
            path = "\${3rd}/luv/library";
            words = ["vim%.uv"];
          }
        ];
      };

      todo-comments = {
        enable = true;
        settings.signs = false;
      };

      mini = {
        enable = true;
        modules = {
          ai = {n_lines = 500;};
          surround = {};
          pairs = {};
          move = {};
          statusline = {
            use_icons = true;
            section_location.__raw = "function() return '%2l:%-2v' end";
          };
        };
      };

      lsp = {
        enable = true;
        keymaps.lspBuf = {
          "grn" = "rename";
          "gra" = {
            action = "code_action";
            mode = ["n" "x"];
          };
          "grr" = "references";
          "gri" = "implementation";
          "grd" = "definition";
          "grD" = "declaration";
          "gO" = "document_symbol";
          "gW" = "workspace_symbol";
          "grt" = "type_definition";
        };
      };

      lsp.servers = {
        nixd = {
          enable = true;
          settings.nixd = {
            formatting.command = ["alejandra"];
            nixpkgs.expr = "import (builtins.getFlake \"/etc/nixos/\").inputs.nixpkgs { }";
            options.nixos.expr = "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.x86_64-linux.options";
          };
        };
        pyright.enable = true;
        ruff.enable = true;
        lua_ls = {
          enable = true;
          settings.Lua = {
            completion.callSnippet = "Replace";
          };
        };
      };

      lsp.diagnostics = {
        severity_sort = true;
        float.border = "rounded";
        float.source = "if_many";
        underline.severity = "ERROR";
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>r";
        action.__raw = ''
          function()
            local file = vim.fn.expand('%:p')
            local term = require("toggleterm.terminal").Terminal:new({
              cmd = "python3 " .. vim.fn.shellescape(file),
              direction = "horizontal",
              close_on_exit = false,
              auto_scroll = true,
            })
            term:toggle()
          end
        '';
        options.desc = "[R]un Python file";
      }
      {
        mode = "n";
        key = "\\";
        action = "<cmd>Neotree toggle<cr>";
        options = {
          desc = "Toggle File Explorer";
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
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR>";
      }
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
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w><C-h>";
        options.desc = "Move focus to the left window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w><C-l>";
        options.desc = "Move focus to the right window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w><C-j>";
        options.desc = "Move focus to the lower window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w><C-k>";
        options.desc = "Move focus to the upper window";
      }
    ];

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      have_nerd_font = true;
    };

    opts = {
      clipboard = "unnamedplus";
      number = true;
      relativenumber = true;
      mouse = "a";
      showmode = false;
      breakindent = true;
      undofile = true;
      ignorecase = true;
      smartcase = true;
      signcolumn = "yes";
      updatetime = 250;
      timeoutlen = 300;
      splitright = true;
      splitbelow = true;
      smoothscroll = true;
      list = true;
      listchars = {
        tab = "» ";
        trail = "·";
        nbsp = "␣";
      };
      inccommand = "split";
      cursorline = true;
      scrolloff = 10;
      confirm = true;
    };

    extraConfigLua = ''
      require("tiny-inline-diagnostic").setup({
        preset = "modern",
        transparent_bg = true,
        transparent_cursorline = true,
        signs = {
          arrow = "  ",
        },
        hi = {
          error = "DiagnosticError",
          warn  = "DiagnosticWarn",
          info  = "DiagnosticInfo",
          hint  = "DiagnosticHint",
        },
        mixing_color = "None",
      })
      vim.diagnostic.config({ virtual_text = false })
      require('neoscroll').setup({
        mappings = {
          },
          hide_cursor = true,
          stop_eof = true,
          respect_scrolloff = true,
          cursor_scrolls_alone = false,
          duration_multiplier = 0.8,
          easing = 'cubic',
        })
        local neoscroll = require('neoscroll')
        local scroll_opts = {
          duration = 60,
          easing = 'quadratic',
          cursor_scrolls_alone = true,
        }
        vim.keymap.set('n', '<ScrollWheelUp>', function()
          require('neoscroll').scroll(-5, { duration = 80, easing = 'quadratic' })
        end)
        vim.keymap.set('n', '<ScrollWheelDown>', function()
          require('neoscroll').scroll(5, { duration = 80, easing = 'quadratic' })
        end)
        vim.keymap.set('i', '<ScrollWheelUp>', function()
          require('neoscroll').scroll(-5, { duration = 80, easing = 'quadratic' })
        end)
        vim.keymap.set('i', '<ScrollWheelDown>', function()
          require('neoscroll').scroll(5, { duration = 80, easing = 'quadratic' })
        end)

        vim.api.nvim_create_autocmd("TextYankPost", {
          group = vim.api.nvim_create_augroup("highlight_on_yank", { clear = true }),
          desc = "Briefly highlight yanked text",
          callback = function()
            vim.hl.on_yank({
              higroup = "IncSearch",
              timeout   = 150,
              on_visual = true,
            })
          end,
        })
        require("guess-indent").setup {}
        require("leetcode").setup {
          lang = "python3",
          description = { position = "bottom" },
        }
        vim.api.nvim_create_autocmd("LspAttach", {
          group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
          callback = function(event)
            local map = function(keys, func, desc, mode)
              mode = mode or "n"
              vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
            end
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, { bufnr = event.buf }) then
              local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
              vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.document_highlight,
              })
              vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.clear_references,
              })
              vim.api.nvim_create_autocmd("LspDetach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                callback = function(event2)
                  vim.lsp.buf.clear_references()
                  vim.api.nvim_clear_autocmds { group = "kickstart-lsp-highlight", buffer = event2.buf }
                end,
              })
            end
            if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, { bufnr = event.buf }) then
              map("<leader>th", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
              end, "[T]oggle Inlay [H]ints")
            end
          end,
        })
      local builtin = require("telescope.builtin")
      local themes = require("telescope.themes")
      require("flash").setup({
        labels = "asdfghjklqwertyuiopzxcvbnm",
        search = {
          multi_window = true,
        },
        jump = {
          autojump = true,
        },
      })
      vim.keymap.set({ "n", "x", "o" }, "f", function()
        require("flash").jump()
      end, { desc = "Flash" })
      vim.keymap.set({ "n", "x", "o" }, "S", function()
        require("flash").treesitter()
      end, { desc = "Flash Treesitter" })
      vim.keymap.set("o", "r", function()
        require("flash").remote()
      end, { desc = "Remote Flash" })
    '';

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
      };
    };
  };
}
