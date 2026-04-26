{pkgs, ...}: {
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    enableBashIntegration = false;
    enableZshIntegration = true;
    settings = {
      manager = {
        show_hidden = true;
        sort_by = "modified";
        sort_sensitive = false;
        sort_reverse = true;
      };
      preview = {
        max_width = 800;
        max_height = 900;
        image_filter = "lanczos3";
      };
    };
  };
}
