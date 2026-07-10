{config, ...}: {
  imports = [
    ../../../modules/system/macos/boring-notch.nix
  ];

  homebrew = {
    brews = [
      "acsandmann/tap/rift"
      "FelixKratz/formulae/borders"
    ];
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = ["ghostty" "raycast"];
  };
}
