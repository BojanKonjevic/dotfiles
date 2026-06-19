{
  userConfig,
  pkgs,
  ...
}: let
  flakePath = userConfig.osFlakePath;
  nixOptions = {
    enable = true;
    target = {
      args = [];
      installable =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "${flakePath}#darwinConfigurations.${userConfig.hostname}.options"
        else "${flakePath}#nixosConfigurations.${userConfig.hostname}.options";
    };
  };
in {
  programs.nixvim = {
    plugins = {
      lazydev = {
        enable = true;
        settings = {
          library = [
            {
              path = "\${3rd}/luv/library";
              words = ["vim%.uv"];
            }
          ];
        };
      };
      lspconfig.enable = true;
    };

    lsp = {
      keymaps = [
        {
          key = "grn";
          lspBufAction = "rename";
        }
        {
          key = "gra";
          lspBufAction = "code_action";
          mode = ["n" "x"];
        }
        {
          key = "grr";
          lspBufAction = "references";
        }
        {
          key = "gri";
          lspBufAction = "implementation";
        }
        {
          key = "grd";
          lspBufAction = "definition";
        }
        {
          key = "grD";
          lspBufAction = "declaration";
        }
        {
          key = "gO";
          lspBufAction = "document_symbol";
        }
        {
          key = "gW";
          lspBufAction = "workspace_symbol";
        }
        {
          key = "grt";
          lspBufAction = "type_definition";
        }
      ];
      servers = {
        nixd = {
          enable = true;
          config.settings.nixd = {
            formatting.command = ["alejandra"];
            nixpkgs.expr = "import (builtins.getFlake \"${flakePath}\").inputs.nixpkgs { }";
            options = nixOptions;
          };
        };
        pyright.enable = true;
        ruff.enable = true;
        lua_ls = {
          enable = true;
          config.settings.Lua.completion.callSnippet = "Replace";
        };
        ts_ls.enable = true;
        eslint.enable = true;
      };
    };

    diagnostic.settings = {
      severity_sort = true;
      float = {
        border = "rounded";
        source = "if_many";
      };
      underline.severity = "ERROR";
    };
  };
}
