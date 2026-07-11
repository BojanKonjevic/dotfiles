{config, ...}: {
  imports = [
    ../../../modules/system/macos/boring-notch.nix
    ../../../modules/system/macos/mouse.nix
    ../../../modules/system/macos/raycast
    ../../../modules/system/macos/stats.nix
  ];

  homebrew = {
    brews = [
      "acsandmann/tap/rift"
      "FelixKratz/formulae/borders"
    ];
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = ["ghostty"];
  };
}
