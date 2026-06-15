{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = [pkgs.vimPlugins.leetcode-nvim];

    extraConfigLua = ''
      require("leetcode").setup({
        lang = "python3",
        description = { position = "bottom" },
      })
    '';

    keymaps = [
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
  };
}
