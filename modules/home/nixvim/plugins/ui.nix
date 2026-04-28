{...}: {
  programs.nixvim.plugins = {
    web-devicons.enable = true;

    todo-comments = {
      enable = true;
      settings.signs = false;
    };

    which-key = {
      enable = true;
      settings = {
        delay = 0;
        icons.mappings = true;
        icons.keys = {};
        spec = [
          {
            __unkeyed-1 = "<leader>x";
            name = "[X] Trouble";
          }
          {
            __unkeyed-1 = "<leader>s";
            name = "[S]earch";
          }
          {
            __unkeyed-1 = "<leader>g";
            name = "[G]it";
          }
          {
            __unkeyed-1 = "<leader>h";
            name = "[H]unk";
          }
        ];
      };
    };

    lualine = {
      enable = true;
      settings = {
        options = {
          component_separators = {
            left = "";
            right = "";
          };
          section_separators = {
            left = "";
            right = "";
          };
          globalstatus = true;
        };
        sections = {
          lualine_a = [
            {
              __unkeyed-1 = "mode";
              separator = {
                left = "";
                right = "";
              };
            }
          ];
          lualine_b = [
            "branch"
            {
              __unkeyed-1 = "diff";
              symbols = {
                added = " ";
                modified = " ";
                removed = " ";
              };
            }
            {
              __unkeyed-1 = "diagnostics";
              symbols = {
                error = " ";
                warn = " ";
                info = " ";
                hint = "󰝶 ";
              };
            }
          ];
          lualine_c = [
            {
              __unkeyed-1 = "filename";
              path = 1;
              symbols = {
                modified = "  ";
                readonly = " ";
                unnamed = " ";
              };
            }
          ];
          lualine_x = [
            {
              __unkeyed-1.__raw = ''
                function()
                  local clients = vim.lsp.get_clients({ bufnr = 0 })
                  if #clients == 0 then return "" end
                  local names = {}
                  for _, c in ipairs(clients) do
                    table.insert(names, c.name)
                  end
                  return "󰒋 " .. table.concat(names, ", ")
                end
              '';
              color = {fg = "#cba6f7";};
            }
            "encoding"
            {
              __unkeyed-1 = "fileformat";
              symbols = {
                unix = " ";
                dos = " ";
                mac = " ";
              };
            }
            "filetype"
          ];
          lualine_y = ["progress"];
          lualine_z = [
            {
              __unkeyed-1 = "location";
              separator = {
                left = "";
                right = "";
              };
            }
          ];
        };
        inactive_sections = {
          lualine_a = [];
          lualine_b = [];
          lualine_c = ["filename"];
          lualine_x = ["location"];
          lualine_y = [];
          lualine_z = [];
        };
      };
    };
  };
}
