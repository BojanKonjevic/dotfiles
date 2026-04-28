{...}: {
  programs.nixvim.plugins = {
    # Tab is overridden in keymaps.nix with explicit \t fallback
    blink-cmp = {
      enable = true;
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
        list.selection = "auto_insert";
      };
      sources = {
        default = ["lsp" "path" "snippets" "lazydev"];
        providers.lazydev = {
          module = "lazydev.integrations.blink";
          score_offset = 100;
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
        };
      };
    };
  };
}
