{config, ...}: {
  homebrew = {
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      "acsandmann/tap/rift"
      "FelixKratz/formulae/borders"
    ];
    casks = ["ghostty" "raycast"];
  };
}
