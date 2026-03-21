{
  pkgs,
  userConfig,
  ...
}: {
  programs.nixvim = {
    enable = true;

    extraPackages = with pkgs; [
      alejandra
      stylua
      lazygit
    ];

    extraPlugins = with pkgs.vimPlugins; [
      diffview-nvim
      undotree
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
          close_on_exit = false;
        };
      };

      treesitter = {
        enable = true;
        settings = {
          ensure_installed = [
            "nix"
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
        settings = {
          signs = {
            add.text = "+";
            change.text = "~";
            delete.text = "_";
            topdelete.text = "‾";
            changedelete.text = "~";
          };
          on_attach.__raw = ''
            function(bufnr)
              local gs = package.loaded.gitsigns
              local function map(mode, l, r, desc)
                vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
              end
              map('n', ']h', gs.next_hunk, 'Next [H]unk')
              map('n', '[h', gs.prev_hunk, 'Prev [H]unk')
              map('n', '<leader>hs', gs.stage_hunk, '[H]unk [S]tage')
              map('n', '<leader>hu', gs.undo_stage_hunk, '[H]unk [U]ndo stage')
              map('n', '<leader>hS', gs.stage_buffer, '[H]unk [S]tage buffer')
              map('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, '[H]unk [S]tage selection')
              map('n', '<leader>hr', gs.reset_hunk, '[H]unk [R]eset')
              map('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, '[H]unk [R]eset selection')
              map('n', '<leader>hR', gs.reset_buffer, '[H]unk [R]eset buffer')
              map('n', '<leader>hp', gs.preview_hunk, '[H]unk [P]review')
              map('n', '<leader>hb', function() gs.blame_line { full = true } end, '[H]unk [B]lame line')
              map({'o','x'}, 'ih', gs.select_hunk, 'select hunk')
            end
          '';
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
            {
              __unkeyed-1 = "<leader>g";
              name = "[G]it";
            }
            {
              __unkeyed-1 = "<leader>h";
              name = "[H]unk";
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
            python = ["ruff_format"];
          };
        };
      };

      blink-cmp = {
        enable = true;
        appearance.nerd_font_variant = "mono";
        keymap = {
          preset = "none";
          "<Tab>" = ["accept" "fallback"];
          "<S-Tab>" = ["select_prev" "fallback"];
          "<C-n>" = ["select_next" "fallback"];
          "<C-p>" = ["select_prev" "fallback"];
          "<C-space>" = ["show" "show_documentation" "hide_documentation"];
          "<C-e>" = ["hide" "fallback"];
          "<C-f>" = ["snippet_forward" "fallback"];
          "<C-b>" = ["snippet_backward" "fallback"];
        };
        snippets.preset = "default";
        completion = {
          documentation.auto_show = true;
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
        fuzzy.implementation = "prefer_rust_with_warning";
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
        servers = {
          nixd = {
            enable = true;
            settings.nixd = {
              formatting.command = ["alejandra"];
              nixpkgs.expr = "import (builtins.getFlake \"${userConfig.osFlakePath}\").inputs.nixpkgs { }";
              options.nixos.expr = "(builtins.getFlake \"${userConfig.osFlakePath}\").nixosConfigurations.${userConfig.hostname}.options";
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
        diagnostics = {
          severity_sort = true;
          float.border = "rounded";
          float.source = "if_many";
          underline.severity = "ERROR";
        };
      };
    };

    keymaps = [
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
      {
        mode = "n";
        key = "<leader>u";
        action = "<cmd>UndotreeToggle<CR>";
        options.desc = "[U]ndo tree";
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

    extraFiles = {
      "plugin/blink.lua".text = ''
        vim.schedule(function()
          vim.keymap.set("i", "<Tab>", function()
            local blink = require("blink.cmp")
            if blink.is_visible() then
              blink.accept()
            else
              return "\t"
            end
          end, { expr = true, silent = true, noremap = true, desc = "blink accept" })
        end)
      '';

      "plugin/diffview.lua".text = ''
        require("diffview").setup({
          enhanced_diff_hl = true,
          view = {
            default = { layout = "diff2_horizontal" },
            merge_tool = { layout = "diff3_horizontal" },
          },
          keymaps = {
            view = {
              { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
            },
            file_panel = {
              { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
            },
            file_history_panel = {
              { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
            },
          },
        })
      '';

      "plugin/lazygit.lua".text = ''
        local Terminal = require("toggleterm.terminal").Terminal
        local lazygit = Terminal:new({
          cmd = "lazygit",
          direction = "float",
          float_opts = {
            border = "rounded",
            width = math.floor(vim.o.columns * 0.92),
            height = math.floor(vim.o.lines * 0.82),
          },
          hidden = true,
          on_open = function(term)
            vim.keymap.set("t", "<C-g>", function() term:toggle() end, { buffer = term.bufnr })
          end,
        })
        vim.keymap.set("n", "<C-g>", function() lazygit:toggle() end, { desc = "Toggle Lazygit" })
      '';

      "plugin/diagnostic.lua".text = ''
        require("tiny-inline-diagnostic").setup({
          preset = "modern",
          transparent_bg = true,
          transparent_cursorline = true,
          signs = {
            arrow = "  ",
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
      '';

      "plugin/neoscroll.lua".text = ''
        require("neoscroll").setup({
          mappings = {},
          hide_cursor = true,
          stop_eof = true,
          respect_scrolloff = true,
          cursor_scrolls_alone = false,
          duration_multiplier = 0.8,
          easing = "cubic",
        })
        vim.keymap.set("n", "<ScrollWheelUp>", function()
          require("neoscroll").scroll(-5, { duration = 80, easing = "quadratic" })
        end)
        vim.keymap.set("n", "<ScrollWheelDown>", function()
          require("neoscroll").scroll(5, { duration = 80, easing = "quadratic" })
        end)
        vim.keymap.set("i", "<ScrollWheelUp>", function()
          require("neoscroll").scroll(-5, { duration = 80, easing = "quadratic" })
        end)
        vim.keymap.set("i", "<ScrollWheelDown>", function()
          require("neoscroll").scroll(5, { duration = 80, easing = "quadratic" })
        end)
        vim.keymap.set("n", "<leader>r", function()
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
        end, { desc = "[R]un Python file" })
      '';

      "plugin/autocmds.lua".text = ''
        vim.api.nvim_create_autocmd("TextYankPost", {
          group = vim.api.nvim_create_augroup("highlight_on_yank", { clear = true }),
          desc = "Briefly highlight yanked text",
          callback = function()
            vim.hl.on_yank({
              higroup = "IncSearch",
              timeout = 150,
              on_visual = true,
            })
          end,
        })
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
            if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, { bufnr = event.buf }) then
              map("<leader>th", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
              end, "[T]oggle Inlay [H]ints")
            end
          end,
        })
      '';

      "plugin/flash.lua".text = ''
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

      "plugin/misc.lua".text = ''
        require("guess-indent").setup {}
        require("leetcode").setup {
          lang = "python3",
          description = { position = "bottom" },
        }
      '';
    };

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
      };
    };
  };
}
