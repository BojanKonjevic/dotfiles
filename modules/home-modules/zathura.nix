{...}: {
  flake.homeModules.zathura = {...}: {
    programs.zathura = {
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
  };
}
