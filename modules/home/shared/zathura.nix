{
  lib,
  pkgs,
  ...
}: {
  programs.zathura = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    enable = true;
    options = {
      recolor = "true";
      recolor-reverse-video = "true";
      recolor-keephue = "true";
      guioptions = "none";
      selection-clipboard = "clipboard";
    };
    mappings = {
      j = "scroll down";
      k = "scroll up";
    };
  };
}
