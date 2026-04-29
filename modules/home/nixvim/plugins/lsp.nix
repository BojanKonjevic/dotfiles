{userConfig, ...}: {
  programs.nixvim.plugins = {
    lazydev = {
      enable = true;
      settings.library = [
        {
          path = "\${3rd}/luv/library";
          words = ["vim%.uv"];
        }
      ];
    };

    lsp = {
      enable = true;
      keymaps.lspBuf = {
        "grn" = "rename";
        "gra" = {
          action = "code_action";
          mode = ["n" "x"];
        };
        "grr" = "references";
        "gri" = "implementation";
        "grd" = "definition";
        "grD" = "declaration";
        "gO" = "document_symbol";
        "gW" = "workspace_symbol";
        "grt" = "type_definition";
      };
      diagnostics = {
        severity_sort = true;
        float.border = "rounded";
        float.source = "if_many";
        underline.severity = "ERROR";
      };
      servers = {
        nixd = {
          enable = true;
          settings.nixd = {
            formatting.command = ["alejandra"];
            nixpkgs.expr = "import (builtins.getFlake \"${userConfig.osFlakePath}\").inputs.nixpkgs { }";
            options.nixos.expr = "(builtins.getFlake \"${userConfig.osFlakePath}\").nixosConfigurations.${userConfig.hostname}.options";
            options.home-manager.expr = ''
              (builtins.getFlake "${userConfig.hmFlakePath}").nixosConfigurations.${userConfig.hostname}.options.home-manager.users.${userConfig.username}
            '';
          };
        };
        pyright.enable = true;
        ruff.enable = true;
        lua_ls = {
          enable = true;
          settings.Lua.completion.callSnippet = "Replace";
        };
      };
    };
  };
}
