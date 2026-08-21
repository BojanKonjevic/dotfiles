{pkgs, ...}: {
  home.file."Documents/Obsidian/Tags.md" = {
    force = false;
    text = ''
      # Allowed Tags

      One tag per line. Lines starting with `#` or blank lines are ignored.

      architecture
      array
      binary-search
      boyer-moore-majority-vote-algorithm
      bucket-sort
      codebase
      code-review
      counting
      daily
      debugging
      design
      divide-and-conquer
      dynamic-programming
      greedy
      hash-function
      hash-table
      html
      leetcode
      linked-list
      math
      matrix
      merge-sort
      meta
      personal
      planning
      prefix-sum
      queue
      quicksort
      simulation
      skill
      sliding-window
      sorting
      stack
      string
      study-sourcing
      tdd
      testing
      two-pointers
      unslop
      writing
    '';
  };
  home.file."Documents/Obsidian/Templates/Daily.md" = {
    force = false;
    text = ''

      # {{date}}
    '';
  };
  home.file."Documents/Obsidian/Templates/Leetcode.md" = {
    force = false;
    text = ''
      ---
      tags: [leetcode]
      ---

      # {{title}}

      - **Link:**
      - **Difficulty:**
      - **Date:** {{date}}

      ## Approach

      ## Complexity

      - Time:
      - Space:

      ## Code

      ## Notes
    '';
  };
  home.file."Documents/Obsidian/Templates/Skill.md" = {
    force = false;
    text = ''
      ---
      tags:
        - skill
      description: Fill in what this skill is triggered by
      name: {{title}}
      ---

      # {{title}}

      ## Instructions
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
          folder = "daily",
          date_format = "%Y-%m-%d",
          template = "Daily.md",
          default_tags = {"daily"},
        },
        templates = {
          folder = "Templates",
          date_format = "%Y-%m-%d",
          time_format = "%H:%M",
          customizations = {
            leetcode = {
              notes_subdir = "leetcode",
            },
          },
        },
        note_id_func = function(title)
          if title ~= nil and title ~= "" then
            return title
          end
          return tostring(os.time())
        end,
        frontmatter = {
          func = function(note)
            local out = {
              id = note.id,
              tags = note.tags or {},
            }
            if note.metadata ~= nil then
              for k, v in pairs(note.metadata) do
                out[k] = v
              end
            end
            return out
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
        key = "<leader>ol";
        action.__raw = ''
          function()
            local title = vim.fn.input("Problem name: ")
            if title ~= "" then
              vim.cmd("Obsidian new_from_template " .. title .. " Leetcode.md")
            end
          end
        '';
        options.desc = "New leetcode note";
      }
      {
        mode = "n";
        key = "<leader>os";
        action.__raw = ''
          function()
            local name = vim.fn.input("Skill name: ")
            if name ~= "" then
              vim.cmd("Obsidian new_from_template " .. name .. " Skill.md")
            end
          end
        '';
        options.desc = "New skill note";
      }
      {
        mode = "n";
        key = "<leader>od";
        action = "<cmd>Obsidian today<CR>";
        options.desc = "Open daily note";
      }
      {
        mode = "n";
        key = "<leader>on";
        action = "<cmd>Obsidian new<CR>";
        options.desc = "New note";
      }
      {
        mode = "n";
        key = "<leader>of";
        action = "<cmd>Obsidian search<CR>";
        options.desc = "Search vault";
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
