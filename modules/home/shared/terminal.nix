{
  theme,
  config,
  pkgs,
  lib,
  inputs,
  userConfig,
  ...
}: let
  nix-search = inputs.nix-search-tv.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home.packages = with pkgs; [
    nix-search
    ansifilter
    nh
    speedtest-go
    eza
    calcurse
    delta
    lazygit
  ];
  programs.zoxide.enable = true;
  programs.broot.enable = true;
  programs.bat.enable = true;
  programs.btop.enable = true;
  programs.cava.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user.name = userConfig.fullName;
      user.email = userConfig.email;
      init.defaultBranch = "main";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        dark = true;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "Catppuccin Mocha";
      };
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };
  };
  programs.ghostty = {
    enable = true;
    package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;
    settings = {
      font-family = theme.fontName;
      font-family-bold = theme.fontName;
      font-family-italic = theme.fontName;
      font-family-bold-italic = theme.fontName;

      cursor-style = "block";
      cursor-style-blink = false;

      window-decoration = false;

      window-padding-x = "10,10";
      window-padding-y = "0,10";

      font-style = "Bold";
      font-style-bold = "Bold";
      font-style-italic = "Bold Italic";
      font-style-bold-italic = "Bold Italic";

      copy-on-select = false;
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-paste-protection = false;

      shell-integration = "zsh";

      confirm-close-surface = false;

      theme = "catppuccin-mocha";

      background-opacity = 0.90;
      background-opacity-cells = true;
      background-blur = true;
    };
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
    shellAliases = let
      nhSwitch =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "nh darwin switch"
        else "nh os switch";
    in {
      v = "nvim";
      lg = "lazygit";
      oc = "opencode";
      vf = "nvim +'lua vim.defer_fn(function() require(\"telescope.builtin\").find_files() end, 0)'";
      dev = "nix develop";
      cal = "calcurse";
      hf = "cd ${userConfig.dotfilesDir} && nvim +'lua vim.defer_fn(function() require(\"telescope.builtin\").find_files() end, 0)'";
      leet = "nvim -c 'Leet'";
      n = "nvim ${userConfig.notesFile}";
      ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";
      ls = "eza --icons -l";
      net = "speedtest-go --server=14476";
      cat = "bat";
      l = "eza -alh --icons --group-directories-first";
      br = "br --hidden";
      brd = "br --sizes --sort-by-size";
      yt = "yttranscript";
      gi = "ingest";
      nr = nhSwitch;
      ngc = "nh clean all --keep 10";
      gp = "git push";
    };
    initContent = ''
      export PATH="${userConfig.homeDirectory}/.local/bin:$PATH"
      export CACHIX_AUTH_TOKEN="$(cat /run/agenix/cachix-token 2>/dev/null)"
      export UV_PUBLISH_TOKEN="$(cat /run/agenix/pypi-key 2>/dev/null)"

      nu() {
        ${
        if pkgs.stdenv.hostPlatform.isDarwin
        then "nh darwin switch -u"
        else "nh os switch -u"
      } \
          && cachix push bojan-dotfiles /run/current-system \
          && cachix push bojan-dotfiles "$HOME/.local/state/nix/profiles/home-manager" \
          ${
        if pkgs.stdenv.hostPlatform.isDarwin
        then ''
          && echo "Updating Homebrew..." \
          && brew update \
          && brew upgrade \
          && brew cleanup
        ''
        else ""
      }
      }

      gc() {
        git commit -m "$*"
      }

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list \
          'm:{a-zA-Z}={A-Za-z}' \
          'r:|[._-]=* r:|=*'

      setopt HIST_IGNORE_SPACE
      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHD_SILENT

      export NH_OS_FLAKE="${userConfig.dotfilesDir}"
      export NH_DARWIN_FLAKE="${userConfig.dotfilesDir}"
      export STARSHIP_VI_MODE=1

      zvm_after_init() {
        eval "$(fzf --zsh)"
        if [[ -z "$_direnv_hooked" ]]; then
          eval "$(direnv hook zsh)"
          export _direnv_hooked=1
        fi
      }
    '';
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
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      style = "compact";
      search_mode = "fuzzy";
      filter_mode_shell_up_arrow = "session";
      show_preview = true;
      exit_mode = "return-query";
      secrets_filter = true;
    };
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
  programs.direnv = {
    enable = true;
    enableZshIntegration = false;
    nix-direnv.enable = true;
    config = {
      hide_env_diff = true;
    };
  };
  home.file.".hushlogin".text = "";
}
