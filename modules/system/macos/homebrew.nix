{
  userConfig,
  inputs,
  lib,
  ...
}: {
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
  system.activationScripts.setup-homebrew.text = lib.mkAfter ''
    TRUST_DIR="${userConfig.homeDirectory}/.config/homebrew"
    mkdir -p "$TRUST_DIR"
    rm -f "${userConfig.homeDirectory}/.homebrew/trust.json"
    cat > "$TRUST_DIR/trust.json" <<'TRUSTEOF'
    {
      "trustedtaps": [
        "acsandmann/tap",
        "felixkratz/formulae"
      ],
      "trustedformulae": [
        "acsandmann/tap/rift",
        "felixkratz/formulae/borders"
      ]
    }
    TRUSTEOF
  '';
}
