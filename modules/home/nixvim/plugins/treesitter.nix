{pkgs, ...}: {
  programs.nixvim.plugins.treesitter = {
    enable = true;
    settings = {
      auto_install = false;
      highlight.enable = true;
      indent.enable = true;
    };
    grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      bash
      css
      diff
      html
      json
      lua
      luadoc
      markdown
      markdown-inline
      nix
      python
      query
      vim
      vimdoc
    ];
  };
}
