{
  pkgs,
  lib,
  ...
}: let
  bootstrap = pkgs.writeShellScriptBin "bootstrap" ''
    export PATH="${lib.makeBinPath [
      pkgs.git
      pkgs.mkpasswd
      pkgs.sbctl
      pkgs.home-manager
    ]}:$PATH"
    exec ${pkgs.bash}/bin/bash ${../scripts/bootstrap.sh} "$@"
  '';

  welcome = ''
    ╔══════════════════════════════════════════════════╗
    ║           NixOS Installer — Bojan's ISO          ║
    ╚══════════════════════════════════════════════════╝

    Run "bootstrap" to install NixOS from your dotfiles.

    Available tools:
      • neovim (v)   • rg (ripgrep)   • fd   • fzf
      • bat (cat)    • eza (ls)       • btop • zoxide (cd)
      • git          • delta          • jq
  '';
in {
  # ── ISO image settings ─────────────────────────────────────────────────────
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  image.baseName = lib.mkForce "nixos-custom-installer";
  image.fileName = lib.mkForce "nixos-custom-installer.iso";
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  # ── Nix ────────────────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    download-buffer-size = 134217728;
    substituters = [
      "https://cache.nixos.org"
      "https://bojan-dotfiles.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "bojan-dotfiles.cachix.org-1:35eXWoN9Ob91Tn6cEhgLJ+6a09KMnZfRzKHbkQrPOX0="
    ];
  };

  # ── Networking ─────────────────────────────────────────────────────────────
  networking.hostName = lib.mkForce "installer";

  # ── Packages ───────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core bootstrap tool
    bootstrap

    # Editor
    neovim

    # Search / navigation
    ripgrep
    fd
    fzf
    zoxide

    # Better CLI tools
    bat
    eza
    jq
    delta

    # System monitoring
    htop
    btop

    # Disk tools
    parted
    gptfdisk

    # Bootstrap dependencies
    git
    mkpasswd
    sbctl
    home-manager

    # Network
    curl
    wget
  ];

  # ── Neovim ─────────────────────────────────────────────────────────────────
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    configure.customRC = ''
      set number relativenumber
      set expandtab tabstop=2 shiftwidth=2
      set ignorecase smartcase
      set scrolloff=8
      set splitright splitbelow
      syntax on
      colorscheme habamax
    '';
  };

  # ── Zsh (Fixed) ────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;

    interactiveShellInit = ''
      # Show welcome message only once per shell session
      if [[ -z "$WELCOME_SHOWN" ]]; then
        echo -e "${welcome}"
        export WELCOME_SHOWN=1
      fi

      # Tool initializations
      eval "$(zoxide init zsh)"
      eval "$(fzf --zsh)"
    '';
  };

  # ── Starship prompt ────────────────────────────────────────────────────────
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$directory$git_branch$git_status$nix_shell$character";
      directory.truncation_length = 3;
      nix_shell = {
        symbol = "❄️ ";
        format = "[$symbol$name]($style) ";
      };
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
      };
    };
  };

  # ── Shell aliases ──────────────────────────────────────────────────────────
  environment.shellAliases = {
    v = "nvim";
    ls = "eza --icons -l";
    l = "eza -alh --icons --group-directories-first";
    cat = "bat";
    cd = "z"; # zoxide
    ll = "eza -alh --icons --group-directories-first";
  };

  # ── NixOS live user ────────────────────────────────────────────────────────
  users.users.nixos = {
    shell = pkgs.zsh;
    isNormalUser = true;
  };

  # Prevent zsh-newuser-install from spamming on first login
  environment.etc."zsh/zshrc.local".text = ''
    # Disable newuser wizard in the installer ISO
    zsh-newuser-install() { :; }
  '';
}
