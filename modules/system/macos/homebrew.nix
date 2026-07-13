{
  userConfig,
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  trustJson = pkgs.writeText "homebrew-trust.json" (builtins.toJSON {
    trustedtaps = config.nix-homebrew.trust.taps;
    trustedformulae = config.nix-homebrew.trust.formulae;
    trustedcasks = config.nix-homebrew.trust.casks;
  });
in {
  nix-homebrew = {
    enable = true;
    user = userConfig.username;
    autoMigrate = true;
    taps = {
      "FelixKratz/formulae" = inputs.FelixKratz-formulae;
      "acsandmann/tap" = inputs.acsandmann-tap;
    };
    trust = {
      taps = ["FelixKratz/formulae" "acsandmann/tap"];
      formulae = [
        "FelixKratz/formulae/borders"
        "acsandmann/tap/rift"
      ];
    };
  };

  # REVIEW §2.2: "zap" removes ALL user data for removed casks/formulae.
  # Switched to "uninstall" while the cask set is still churning; flip to
  # "zap" once the desktop-app list stabilises.
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    brews = ["mas"];
    casks = [];
    masApps = {};
  };

  # nix-homebrew runs `brew trust` under sudo, which strips XDG_CONFIG_HOME.
  # Homebrew 6.x reads trust from $XDG_CONFIG_HOME/homebrew/trust.json,
  # but sudo's brew trust writes to the fallback ~/.homebrew/trust.json.
  # This appends to nix-homebrew's setup-homebrew to write trust to the right path.
  #
  # Because we overwrite the trust.json file unconditionally on every
  # activation (instead of relying on nix-homebrew's imperative `brew trust`
  # for removal), this sidesteps the upstream caveat documented at:
  # https://github.com/zhaofengli/nix-homebrew#managing-trust — when you
  # remove items from trust lists, the corresponding trust entries *are*
  # removed here, unlike the default imperative path.
  system.activationScripts.setup-homebrew.text = lib.mkBefore ''
    TRUST_DIR="${userConfig.homeDirectory}/.config/homebrew"
    mkdir -p "$TRUST_DIR"

    mkdir -p "${userConfig.homeDirectory}/.homebrew"
    rm -f "${userConfig.homeDirectory}/.homebrew/trust.json"
    ln -sf "$TRUST_DIR/trust.json" "${userConfig.homeDirectory}/.homebrew/trust.json"

    cp ${trustJson} "$TRUST_DIR/trust.json"
    chmod 644 "$TRUST_DIR/trust.json"

    chown "${userConfig.username}:staff" "$TRUST_DIR" "$TRUST_DIR/trust.json"
    chown "${userConfig.username}:staff" "${userConfig.homeDirectory}/.homebrew"
    chown -h "${userConfig.username}:staff" "${userConfig.homeDirectory}/.homebrew/trust.json"
  '';
}
