{config, ...}: {
  imports = [
    ../../../modules/system/macos/boring-notch.nix
    ../../../modules/system/macos/mouse.nix
    ../../../modules/system/macos/raycast
    ../../../modules/system/macos/shottr.nix
    ../../../modules/system/macos/stats.nix
  ];

  homebrew = {
    brews = [
      "acsandmann/tap/rift"
      "FelixKratz/formulae/borders"
    ];
    # NixOS fixed-point evaluation means `config.nix-homebrew.taps` sees the
    # fully merged set here regardless of import order — this is not eval-order-
    # dependent, so boring-notch.nix adding a third tap after this line works
    # correctly without reordering.
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = ["ghostty" "karabiner-elements"];
  };
}
