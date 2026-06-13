{config, ...}: {
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
    TERMINAL = "kitty";
    XDG_TERMINAL = "kitty";
  };
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = null;
      setSessionVariables = false;
      templates = null;
      publicShare = null;
      videos = null;
      download = "${config.home.homeDirectory}/Downloads";
      documents = "${config.home.homeDirectory}/Documents";
      pictures = "${config.home.homeDirectory}/Pictures";
      music = "${config.home.homeDirectory}/Music";
    };
  };
}
