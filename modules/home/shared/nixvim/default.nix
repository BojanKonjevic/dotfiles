{
  pkgs,
  inputs,
  ...
}: {
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
    ./plugins/cpp.nix
  ];

  home.packages = [pkgs.nixd];

  programs.nixvim = {
    enable = true;
    enableMan = false;
    nixpkgs.source = inputs.nixpkgs;

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
      settings = {
        flavour = "mocha";
        transparent_background = true;
      };
    };

    extraPackages = with pkgs; [
      alejandra
      prettierd
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
      "plugin/clipboard.lua".source = ./plugins/clipboard.lua;
    };

    keymaps = [
      {
        mode = "n";
        key = "<D-h>";
        action = "<C-w><C-h>";
        options.desc = "Move focus left";
      }
      {
        mode = "n";
        key = "<D-l>";
        action = "<C-w><C-l>";
        options.desc = "Move focus right";
      }
      {
        mode = "n";
        key = "<D-j>";
        action = "<C-w><C-j>";
        options.desc = "Move focus down";
      }
      {
        mode = "n";
        key = "<D-k>";
        action = "<C-w><C-k>";
        options.desc = "Move focus up";
      }

      {
        mode = "n";
        key = "<D-S-j>";
        action = ":m .+1<CR>==";
        options = {desc = "Move line down";};
      }
      {
        mode = "n";
        key = "<D-S-k>";
        action = ":m .-2<CR>==";
        options = {desc = "Move line up";};
      }
      {
        mode = "v";
        key = "<D-S-j>";
        action = ":m '>+1<CR>gv=gv";
        options = {desc = "Move selection down";};
      }
      {
        mode = "v";
        key = "<D-S-k>";
        action = ":m '<-2<CR>gv=gv";
        options = {desc = "Move selection up";};
      }

      {
        mode = "n";
        key = "<D-s>";
        action = ":w<CR>";
        options = {
          noremap = true;
          silent = true;
        };
      }
      {
        mode = "i";
        key = "<D-s>";
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
        key = "<D-r>";
        action = "<C-r>";
        options.desc = "Redo";
      }
      {
        mode = "n";
        key = "<D-q>";
        action = ":qa<CR>";
        options = {
          noremap = true;
          silent = true;
        };
      }
    ];
  };
}
