{...}: {
  flake.homeModules.nixvim = {
    pkgs,
    userConfig,
    ...
  }: {
    home.packages = [pkgs.nixd];

    programs.nixvim = {
      enable = true;

      extraPackages = with pkgs; [
        alejandra
        stylua
        lazygit
        kdePackages.qtdeclarative
      ];

      extraPlugins = with pkgs.vimPlugins; [
        harpoon2
        grug-far-nvim
        diffview-nvim
        undotree
        tiny-inline-diagnostic-nvim
        flash-nvim
        guess-indent-nvim
        vim-visual-multi
        leetcode-nvim
        neo-tree-nvim
        neoscroll-nvim
        oil-nvim
        trouble-nvim
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
                __unkeyed-1 = "<leader>x";
                name = "[X] Trouble";
              }
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
              qml = ["qmlformat"];
            };
          };
        };

        blink-cmp = {
          enable = true;
          appearance.nerd_font_variant = "mono";
          keymap = {
            preset = "none";
            "<Tab>" = [
              "accept"
              "fallback"
            ];
            "<S-Tab>" = [
              "select_prev"
              "fallback"
            ];
            "<C-n>" = [
              "select_next"
              "fallback"
            ];
            "<C-p>" = [
              "select_prev"
              "fallback"
            ];
            "<C-space>" = [
              "show"
              "show_documentation"
              "hide_documentation"
            ];
            "<C-e>" = [
              "hide"
              "fallback"
            ];
            "<C-f>" = [
              "snippet_forward"
              "fallback"
            ];
            "<C-b>" = [
              "snippet_backward"
              "fallback"
            ];
          };
          snippets.preset = "default";
          completion = {
            documentation.auto_show = true;
            ghost_text.enabled = true;
            list.selection = "auto_insert";
          };
          sources = {
            default = [
              "lsp"
              "path"
              "snippets"
              "lazydev"
            ];
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
            ai = {
              n_lines = 500;
            };
            comment = {};
            surround = {};
            pairs = {};
            move = {};
          };
        };

        lualine = {
          enable = true;
          settings = {
            options = {
              component_separators = {
                left = "";
                right = "";
              };
              section_separators = {
                left = "";
                right = "";
              };
              globalstatus = true;
            };
            sections = {
              lualine_a = [
                {
                  __unkeyed-1 = "mode";
                  separator = {
                    left = "";
                    right = "";
                  };
                }
              ];
              lualine_b = [
                "branch"
                {
                  __unkeyed-1 = "diff";
                  symbols = {
                    added = " ";
                    modified = " ";
                    removed = " ";
                  };
                }
                {
                  __unkeyed-1 = "diagnostics";
                  symbols = {
                    error = " ";
                    warn = " ";
                    info = " ";
                    hint = "󰝶 ";
                  };
                }
              ];
              lualine_c = [
                {
                  __unkeyed-1 = "filename";
                  path = 1;
                  symbols = {
                    modified = "  ";
                    readonly = " ";
                    unnamed = " ";
                  };
                }
              ];
              lualine_x = [
                {
                  __unkeyed-1.__raw = ''
                    function()
                      local clients = vim.lsp.get_clients({ bufnr = 0 })
                      if #clients == 0 then return "" end
                      local names = {}
                      for _, c in ipairs(clients) do
                        table.insert(names, c.name)
                      end
                      return "󰒋 " .. table.concat(names, ", ")
                    end
                  '';
                  color = {fg = "#cba6f7";};
                }
                "encoding"
                {
                  __unkeyed-1 = "fileformat";
                  symbols = {
                    unix = " ";
                    dos = " ";
                    mac = " ";
                  };
                }
                "filetype"
              ];
              lualine_y = ["progress"];
              lualine_z = [
                {
                  __unkeyed-1 = "location";
                  separator = {
                    left = "";
                    right = "";
                  };
                }
              ];
            };
            inactive_sections = {
              lualine_a = [];
              lualine_b = [];
              lualine_c = ["filename"];
              lualine_x = ["location"];
              lualine_y = [];
              lualine_z = [];
            };
          };
        };

        lsp = {
          enable = true;
          keymaps.lspBuf = {
            "grn" = "rename";
            "gra" = {
              action = "code_action";
              mode = [
                "n"
                "x"
              ];
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
                options.home-manager.expr = ''
                  (builtins.getFlake "${userConfig.hmFlakePath}").homeConfigurations.${userConfig.username}.options
                '';
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
        {
          mode = "n";
          key = "<C-p>";
          action.__raw = "function() require('harpoon'):list():prev() end";
          options.desc = "Harpoon prev";
        }
        {
          mode = "n";
          key = "<C-n>";
          action.__raw = "function() require('harpoon'):list():next() end";
          options.desc = "Harpoon next";
        }

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
          key = "-";
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
        "plugin/oil.lua".source = ./nvim/oil.lua;
        "plugin/trouble.lua".source = ./nvim/trouble.lua;
        "plugin/grug-far.lua".source = ./nvim/grug-far.lua;
        "plugin/blink.lua".source = ./nvim/blink.lua;
        "plugin/diffview.lua".source = ./nvim/diffview.lua;
        "plugin/lazygit.lua".source = ./nvim/lazygit.lua;
        "plugin/diagnostic.lua".source = ./nvim/diagnostic.lua;
        "plugin/neoscroll.lua".source = ./nvim/neoscroll.lua;
        "plugin/autocmds.lua".source = ./nvim/autocmds.lua;
        "plugin/flash.lua".source = ./nvim/flash.lua;
        "plugin/misc.lua".source = ./nvim/misc.lua;
      };

      colorschemes.catppuccin = {
        enable = true;
        settings = {
          flavour = "mocha";
        };
      };
    };
  };
}
