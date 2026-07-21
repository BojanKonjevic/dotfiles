# plugins/obsidian.nix
{pkgs, ...}: {
  home.file."Documents/Obsidian/Tags.md" = {
    force = false;
    text = ''
      # Allowed Tags

      One tag per line. Lines starting with `#` (other than this header) or blank lines are ignored.

      leetcode
      daily
      journal
    '';
  };

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      obsidian-nvim
    ];

    extraConfigLua = ''
      require("obsidian").setup({
        legacy_commands = false,
        workspaces = {
          {
            name = "vault",
            path = "~/Documents/Obsidian",
          },
        },
        daily_notes = {
          folder = nil,
          date_format = "%Y-%m-%d",
          template = nil,
          default_tags = {"daily"},
        },
        templates = {
          folder = "Templates",
          date_format = "%Y-%m-%d",
          time_format = "%H:%M",
        },
        note_id_func = function(title)
          return title
        end,
        frontmatter = {
          func = function(note)
            return {
              id = note.id,
              tags = note.tags or {},
            }
          end,
        },
        link = {
          style = "wiki",
        },
        picker = {
          name = "telescope.nvim",
        },
        ui = { enable = false },
      })
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>oo";
        action = "<cmd>Obsidian today<CR>";
        options.desc = "Open daily note";
      }
      {
        mode = "n";
        key = "<leader>of";
        action = "<cmd>Obsidian search<CR>";
        options.desc = "Search vault";
      }
      {
        mode = "n";
        key = "<leader>on";
        action = "<cmd>Obsidian new<CR>";
        options.desc = "New note";
      }
      {
        mode = "n";
        key = "gf";
        action = "<cmd>Obsidian follow_link<CR>";
        options.desc = "Follow link/tag";
      }
      {
        mode = "n";
        key = "<leader>ob";
        action = "<cmd>Obsidian backlinks<CR>";
        options.desc = "Show backlinks";
      }
    ];

    extraFiles = {
      "plugin/obsidian-tags.lua".source = ./obsidian-tags.lua;
      "lua/obsidian-tag-source.lua".source = ./obsidian-tag-source.lua;
    };
  };
}
