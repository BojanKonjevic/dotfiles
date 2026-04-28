{pkgs, ...}: {
  imports = [
    ./plugins/ui.nix
    ./plugins/treesitter.nix
    ./plugins/lsp.nix
    ./plugins/completion.nix
    ./plugins/navigation.nix
    ./plugins/git.nix
    ./plugins/tools.nix
    ./plugins/harpoon.nix
    ./plugins/leetcode.nix
  ];

  home.packages = [pkgs.nixd];

  programs.nixvim = {
    enable = true;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      have_nerd_font = true;
    };

    opts = {
      number = true;
      relativenumber = true;
      cursorline = true;
      signcolumn = "yes";
      scrolloff = 10;
      splitright = true;
      splitbelow = true;
      smoothscroll = true;
      clipboard = "unnamedplus";
      mouse = "a";
      showmode = false;
      breakindent = true;
      undofile = true;
      confirm = true;
      ignorecase = true;
      smartcase = true;
      inccommand = "split";
      updatetime = 250;
      timeoutlen = 300;
      list = true;
      listchars = {
        tab = "» ";
        trail = "·";
        nbsp = "␣";
      };
    };

    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "mocha";
    };

    extraPackages = with pkgs; [
      alejandra
      stylua
      kdePackages.qtdeclarative
      shfmt
    ];

    extraPlugins = with pkgs.vimPlugins; [
      tiny-inline-diagnostic-nvim
      vim-visual-multi
    ];

    extraFiles = {
      "plugin/autocmds.lua".source = ./plugins/autocmds.lua;
      "plugin/diagnostic.lua".source = ./plugins/diagnostic.lua;
    };

    keymaps = [
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
    ];
  };
}
