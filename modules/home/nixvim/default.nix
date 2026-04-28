{pkgs, ...}: {
  imports = [
    ./plugins/ui.nix
    ./plugins/treesitter.nix
    ./plugins/lsp.nix
    ./plugins/completion.nix
    ./plugins/navigation.nix
    ./plugins/git.nix
    ./plugins/tools.nix
    ./keymaps.nix
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
      leetcode-nvim
      harpoon2
    ];

    extraConfigLua = ''
      require("leetcode").setup({
        lang = "python3",
        description = { position = "bottom" },
      })
    '';

    extraFiles = {
      "plugin/autocmds.lua".source = ./plugins/autocmds.lua;
      "plugin/diagnostic.lua".source = ./plugins/diagnostic.lua;
    };
  };
}
