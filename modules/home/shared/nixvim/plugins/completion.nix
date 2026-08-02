{pkgs, ...}: {
  programs.nixvim.plugins = {
    # Tab is overridden in keymaps.nix with explicit \t fallback
    blink-cmp = {
      enable = true;
      settings = {
        appearance.nerd_font_variant = "mono";
        snippets.preset = "default";
        fuzzy.implementation = "prefer_rust_with_warning";
        signature.enabled = true;
        keymap = {
          preset = "none";
          "<S-Tab>" = ["select_prev" "fallback"];
          "<C-n>" = ["select_next" "fallback"];
          "<C-p>" = ["select_prev" "fallback"];
          "<C-space>" = ["show" "show_documentation" "hide_documentation"];
          "<C-e>" = ["hide" "fallback"];
          "<C-f>" = ["snippet_forward" "fallback"];
          "<C-b>" = ["snippet_backward" "fallback"];
        };
        completion = {
          documentation.auto_show = true;
          ghost_text.enabled = true;
          list.selection = {
            preselect = true;
            auto_insert = true;
          };
        };
        sources = {
          default = ["lsp" "path" "snippets" "lazydev" "obsidian_tags"];
          providers = {
            lazydev = {
              module = "lazydev.integrations.blink";
              score_offset = 100;
            };
            obsidian_tags = {
              name = "obsidian_tags";
              module = "obsidian-tag-source";
              enabled.__raw = ''
                function()
                  if vim.bo.filetype ~= "markdown" then
                    return false
                  end
                  local vault_path = vim.fn.expand("~/Documents/Obsidian")
                  local filepath = vim.api.nvim_buf_get_name(0)
                  return vim.startswith(filepath, vault_path)
                end
              '';
            };
          };
        };
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
          bash = ["shfmt"];
          sh = ["shfmt"];
          typescript = ["prettierd"];
          typescriptreact = ["prettierd"];
          javascript = ["prettierd"];
          javascriptreact = ["prettierd"];
          json = ["prettierd"];
          css = ["prettierd"];
          html = ["prettierd"];
          markdown = ["prettierd"];
        };
      };
    };
  };

  programs.nixvim.extraPlugins = let
    neocodeium = pkgs.vimUtils.buildVimPlugin {
      name = "neocodeium";
      src = pkgs.fetchFromGitHub {
        owner = "monkoose";
        repo = "neocodeium";
        rev = "ab8a3da3a66d299ad5422b76ce5ee21b68719296";
        hash = "sha256-rvlTa5nj9Aoelk7taqW5nBSqLZXrLt52jfWc+23toEs=";
      };
      doCheck = false;
    };
  in [neocodeium];

  programs.nixvim.extraConfigLua = ''
    require("neocodeium").setup({
      filter = function(bufnr)
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match("/nvim/leetcode/") then
          return false
        end
      end,
    })
  '';

  programs.nixvim.keymaps = [
    {
      mode = "i";
      key = "<Tab>";
      action.__raw = ''
        function()
          local blink = require("blink.cmp")
          if blink.is_visible() then
            blink.accept()
          else
            return "\t"
          end
        end
      '';
      options = {
        expr = true;
        silent = true;
        noremap = true;
        desc = "blink accept";
      };
    }
    {
      mode = "i";
      key = "<D-f>";
      action.__raw = "function() require('neocodeium').accept() end";
      options.desc = "Accept neocodeium suggestion";
    }
    {
      mode = "i";
      key = "<D-]>";
      action.__raw = "function() require('neocodeium').cycle_or_complete() end";
      options.desc = "Next neocodeium suggestion";
    }
    {
      mode = "i";
      key = "<D-[>";
      action.__raw = "function() require('neocodeium').cycle_or_complete(-1) end";
      options.desc = "Previous neocodeium suggestion";
    }
    {
      mode = "i";
      key = "<D-c>";
      action.__raw = "function() require('neocodeium').clear() end";
      options.desc = "Clear neocodeium suggestion";
    }
  ];
}
