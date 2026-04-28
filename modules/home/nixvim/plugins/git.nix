{...}: {
  programs.nixvim = {
    plugins = {
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
              map('n', ']h', gs.next_hunk,       'Next [H]unk')
              map('n', '[h', gs.prev_hunk,       'Prev [H]unk')
              map('n', '<leader>hs', gs.stage_hunk,       '[H]unk [S]tage')
              map('n', '<leader>hu', gs.undo_stage_hunk,  '[H]unk [U]ndo stage')
              map('n', '<leader>hS', gs.stage_buffer,     '[H]unk [S]tage buffer')
              map('n', '<leader>hr', gs.reset_hunk,       '[H]unk [R]eset')
              map('n', '<leader>hR', gs.reset_buffer,     '[H]unk [R]eset buffer')
              map('n', '<leader>hp', gs.preview_hunk,     '[H]unk [P]review')
              map('n', '<leader>hb', function() gs.blame_line { full = true } end, '[H]unk [B]lame line')
              map('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, '[H]unk [S]tage selection')
              map('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, '[H]unk [R]eset selection')
              map({'o','x'}, 'ih', gs.select_hunk, 'select hunk')
            end
          '';
        };
      };

      diffview = {
        enable = true;
        settings = {
          enhanced_diff_hl = true;
          view = {
            default.layout = "diff2_horizontal";
            merge_tool.layout = "diff3_horizontal";
          };
        };
      };

      lazygit = {
        enable = true;
        settings.floating_window_use_plenary = 0;
      };
    };

    extraConfigLua = ''
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "DiffviewFiles", "DiffviewFileHistory", "DiffviewFileHistoryPanel" },
        callback = function(ev)
          vim.keymap.set("n", "q", "<cmd>DiffviewClose<CR>", { buffer = ev.buf, desc = "Close Diffview" })
        end,
      })
    '';
  };
}
