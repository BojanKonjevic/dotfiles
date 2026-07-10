{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = [pkgs.vimPlugins.harpoon2];

    keymaps = [
      {
        mode = "n";
        key = "<D-a>";
        action.__raw = "function() require('harpoon'):list():add() end";
        options.desc = "Harpoon add file";
      }
      {
        mode = "n";
        key = "<D-e>";
        action.__raw = "function() local h = require('harpoon') h.ui:toggle_quick_menu(h:list()) end";
        options.desc = "Harpoon menu";
      }
      {
        mode = "n";
        key = "<D-1>";
        action.__raw = "function() require('harpoon'):list():select(1) end";
        options.desc = "Harpoon file 1";
      }
      {
        mode = "n";
        key = "<D-2>";
        action.__raw = "function() require('harpoon'):list():select(2) end";
        options.desc = "Harpoon file 2";
      }
      {
        mode = "n";
        key = "<D-3>";
        action.__raw = "function() require('harpoon'):list():select(3) end";
        options.desc = "Harpoon file 3";
      }
      {
        mode = "n";
        key = "<D-4>";
        action.__raw = "function() require('harpoon'):list():select(4) end";
        options.desc = "Harpoon file 4";
      }
    ];
  };
}
