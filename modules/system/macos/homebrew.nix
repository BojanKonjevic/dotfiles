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

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
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
  system.activationScripts.setup-homebrew.text = lib.mkBefore ''
    TRUST_DIR="${userConfig.homeDirectory}/.config/homebrew"
    mkdir -p "$TRUST_DIR"
    rm -f "${userConfig.homeDirectory}/.homebrew/trust.json"
    ln -sf "$TRUST_DIR/trust.json" "${userConfig.homeDirectory}/.homebrew/trust.json"
    cp ${trustJson} "$TRUST_DIR/trust.json"
    chmod 644 "$TRUST_DIR/trust.json"
  '';
}
