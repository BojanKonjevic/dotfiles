{
  config,
  pkgs,
  ...
}: {
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 16;
    };

    settings = {
      scrollback_lines = 5000;
      enable_audio_bell = "no";
      open_url_with = "default";
      url_style = "single";
      copy_on_select = "yes";
      confirm_os_window_close = 0;
      shell_integration = "disabled";
    };

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+h" = "show_scrollback";
    };

    extraConfig = ''
      scrollback_pager bash -c "ansifilter | nvim -c 'set ft=sh | $' -"
      scrollback_pager_history_size 0
      font_family family='JetBrainsMono Nerd Font' style=Bold
      bold_font family='JetBrainsMono Nerd Font' style=Bold
      italic_font family='JetBrainsMono Nerd Font' style='Bold Italic'
      bold_italic_font family='JetBrainsMono Nerd Font' style='Bold Italic'

      cursor_shape block
      cursor_blink_interval 0

      window_padding_width 0 10 10 10
      window_decorations none
      modify_font underline_position 150%
      modify_font cell_height 100%

      repaint_delay 5
      input_delay 0
      sync_to_monitor yes
    '';
  };

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    plugins = [
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];

    shellAliases = {
      pg = "psql -d postgres --dbname";
      dev = "nix develop";
      cal = "calcurse";
      hf = "cd ~/dotfiles/home/ && nvim +'lua vim.defer_fn(function() require(\"telescope.builtin\").find_files() end, 0)'";
      leet = "nvim -c 'Leet'";
      n = "nvim ~/Documents/notes.txt";
      ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";
      f = "thunar .";
      ls = "eza --icons";
      net = "speedtest-go --server=43446";
      cat = "bat";
      l = "eza -alh --icons --group-directories-first";
      br = "br --hidden";
      brd = "br --sizes --sort-by-size";
      wall = "~/scripts/setwall.sh";
      pyproj = "~/scripts/new-python-project.sh";

      nr = "nh os switch";
      hm = "nh home switch";
      nu = "nh os switch -u && nh home switch -u";
      gc = "nh clean all --keep 10";
      ngens = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      hgens = "nix-env --list-generations --profile ~/.local/state/nix/profiles/home-manager";
    };

    initContent = ''
      autoload -Uz compinit
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list \
          'm:{a-zA-Z}={A-Za-z}' \
          'r:|[._-]=* r:|=*'

      setopt HIST_REDUCE_BLANKS
      setopt INC_APPEND_HISTORY

      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHD_SILENT

      export NH_OS_FLAKE="/etc/nixos"
      export NH_HOME_FLAKE="$HOME/home-manager"
      export STARSHIP_VI_MODE=1

      # zsh-vi-mode resets all keybindings on init, so fzf bindings
      # must be registered here or they get wiped out
      zvm_after_init() {
        eval "$(fzf --zsh)"
      }

      # optional: uncomment to use jk as escape (like in nvim)
      # ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
    '';

    history = {
      expireDuplicatesFirst = true;
      extended = true;
      ignoreSpace = true;
      save = 10000;
      size = 10000;
      share = true;
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border=rounded"
      "--preview-window=right:55%:wrap"
    ];
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = ''
        $directory$nix_shell$python$git_branch$git_status$cmd_duration
        $character
      '';
      directory = {
        truncation_length = 3;
      };
      nix_shell = {
        symbol = "❄️ ";
        format = "[$symbol$name]($style) ";
      };
      python = {
        symbol = "🐍";
        format = "[$symbol $version]($style) ";
      };
      package = {
        format = "📦 $version ";
        disabled = false;
      };
      git_branch = {
        symbol = " ";
      };
      git_status = {
        format = "([\\[$all_status$ahead_behind\\]]($style)) ";
      };
      cmd_duration = {
        min_time = 1000;
        format = "󰔚 [$duration]($style) ";
      };
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](blue)";
      };
    };
  };
}
