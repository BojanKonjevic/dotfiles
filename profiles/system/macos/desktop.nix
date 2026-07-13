{
  config,
  inputs,
  ...
}: {
  imports = [
    ../../../modules/system/macos/mouse.nix
    ../../../modules/system/macos/raycast
    ../../../modules/system/macos/rift
  ];

  nix-homebrew.taps."TheBoredTeam/boring-notch" = inputs.boring-notch-brew;
  nix-homebrew.trust = {
    taps = ["TheBoredTeam/boring-notch"];
    casks = ["TheBoredTeam/boring-notch/boring-notch"];
  };

  homebrew = {
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [
      "boring-notch"
      "ghostty"
      "karabiner-elements"
      "shottr"
      "stats"
    ];
  };
}
