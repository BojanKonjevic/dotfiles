{
  pkgs,
  lib,
  ...
}: {
  programs.nixvim = {
    # ── LSP ───────────────────────────────────────────────────────────────
    lsp.servers = {
      clangd = {
        enable = true;
        config.cmd = [
          "clangd"
          "--background-index"
          "--clang-tidy"
          "--header-insertion=iwyu"
        ];
      };
    };

    # ── Formatting ────────────────────────────────────────────────────────
    plugins.conform-nvim.settings.formatters_by_ft.cpp = ["clang-format"];

    extraConfigLua = ''
      -- C++ format on save (C++17 for this project)
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.cpp", "*.hpp", "*.h", "*.cc", "*.cxx" },
        callback = function(args)
          require("conform").format({ bufnr = args.buf, timeout_ms = 500, lsp_format = "fallback" })
        end,
      })

      -- Disable clang-tidy modernize checks for academic project style
      vim.g.clangtidy_checks = "-modernize-*,-cppcoreguidelines-*,-performance-*"
    '';

    # ── Linting ───────────────────────────────────────────────────────────
    plugins.lint.lintersByFt.cpp = ["clangtidy"];

    # ── Keymaps ───────────────────────────────────────────────────────────
    keymaps = [
      {
        mode = "n";
        key = "<leader>q";
        action.__raw = ''
          function()
            -- Get current buffer content
            local buf_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

            -- Create a temporary file that will be deleted automatically
            local temp_cpp = os.tmpname() .. ".cpp"
            local temp_out = os.tmpname()

            -- Write current buffer content to temp file
            local file = io.open(temp_cpp, "w")
            if not file then
              vim.notify("Failed to create temporary file", "error")
              return
            end
            file:write(buf_content)
            file:close()

            -- Build command that compiles and runs, then cleans up
            local cmd = string.format(
              "g++ -std=c++17 -Wall -Wextra -O2 %s -o %s && %s && rm -f %s %s; echo '\\n--- Press any key to close ---' && read -n 1",
              vim.fn.shellescape(temp_cpp),
              vim.fn.shellescape(temp_out),
              vim.fn.shellescape(temp_out),
              vim.fn.shellescape(temp_cpp),
              vim.fn.shellescape(temp_out)
            )

            local term = require("toggleterm.terminal").Terminal:new({
              cmd = cmd,
              direction = "float",
              float_opts = {
                border = "rounded",
                width = math.floor(vim.o.columns * 0.8),
                height = math.floor(vim.o.lines * 0.6),
                row = math.floor(vim.o.lines * 0.2),
                col = math.floor(vim.o.columns * 0.1),
              },
              close_on_exit = false,
            })
            term:toggle()
          end
        '';
        options.desc = "[R] compile and run current C++ file (no permanent files)";
      }
    ];
  };

  # ── Tooling packages ──────────────────────────────────────────────────
  home.packages = with pkgs;
    [
      gcc
      gnumake
      clang-tools
      cppcheck
      diffutils
    ]
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
      valgrind
    ];
}
