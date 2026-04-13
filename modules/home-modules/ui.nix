{...}: {
  flake.homeModules.ui = {
    pkgs,
    config,
    ...
  }: {
    home.packages = with pkgs; [
      swayimg
      mpv
      xarchiver
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      SUDO_EDITOR = "nvim";
      TERMINAL = "kitty";
      XDG_TERMINAL = "kitty";
    };

    xdg = {
      enable = true;
      desktopEntries = {
        nvim = {
          name = "Neovim";
          genericName = "Text Editor";
          comment = "Edit text files in Neovim inside Kitty terminal";
          exec = "kitty nvim %F";
          terminal = false;
          type = "Application";
          icon = "nvim";
          categories = [
            "Development"
            "TextEditor"
            "Utility"
          ];
          startupNotify = true;
        };
        kitty = {
          name = "Kitty";
          genericName = "Terminal Emulator";
          comment = "Fast, feature-rich, GPU based terminal";
          exec = "kitty";
          terminal = false;
          type = "Application";
          icon = "kitty";
          categories = [
            "System"
            "TerminalEmulator"
          ];
          startupNotify = true;
        };
        swayimg = {
          name = "Swayimg";
          genericName = "Image Viewer";
          comment = "Fast and simple image viewer";
          exec = "swayimg %F";
          terminal = false;
          type = "Application";
          icon = "swayimg";
          categories = [
            "Graphics"
            "Viewer"
          ];
          mimeType = [
            "image/png"
            "image/jpeg"
            "image/gif"
            "image/webp"
            "image/svg+xml"
          ];
          startupNotify = true;
        };
        mpv = {
          name = "mpv";
          genericName = "Media Player";
          comment = "Play videos and audio with mpv";
          exec = "mpv %F";
          terminal = false;
          type = "Application";
          icon = "mpv";
          categories = [
            "AudioVideo"
            "Player"
            "Audio"
            "Video"
          ];
          mimeType = [
            "video/mp4"
            "video/webm"
            "video/x-matroska"
            "audio/mp3"
          ];
          startupNotify = true;
        };
      };
      mimeApps = {
        enable = true;
        defaultApplications = {
          "text/plain" = ["nvim.desktop"];
          "text/x-python" = ["nvim.desktop"];
          "text/x-toml" = ["nvim.desktop"];
          "text/x-yaml" = ["nvim.desktop"];
          "text/x-shellscript" = ["nvim.desktop"];
          "application/json" = ["nvim.desktop"];
          "application/toml" = ["nvim.desktop"];
          "application/x-yaml" = ["nvim.desktop"];

          "image/png" = ["swayimg.desktop"];
          "image/jpeg" = ["swayimg.desktop"];
          "image/jpg" = ["swayimg.desktop"];
          "image/gif" = ["swayimg.desktop"];
          "image/webp" = ["swayimg.desktop"];
          "image/svg+xml" = ["swayimg.desktop"];

          "video/mp4" = ["mpv.desktop"];
          "video/webm" = ["mpv.desktop"];
          "video/x-matroska" = ["mpv.desktop"];
          "video/quicktime" = ["mpv.desktop"];

          "application/zip" = ["xarchiver.desktop"];
          "application/x-zip-compressed" = ["xarchiver.desktop"];
          "application/x-7z-compressed" = ["xarchiver.desktop"];
          "application/x-rar" = ["xarchiver.desktop"];
          "application/x-rar-compressed" = ["xarchiver.desktop"];
          "application/x-tar" = ["xarchiver.desktop"];
          "application/x-compressed-tar" = ["xarchiver.desktop"];
          "application/x-bzip-compressed-tar" = ["xarchiver.desktop"];
          "application/x-xz-compressed-tar" = ["xarchiver.desktop"];
          "application/gzip" = ["xarchiver.desktop"];
          "application/x-bzip2" = ["xarchiver.desktop"];
          "application/x-xz" = ["xarchiver.desktop"];
        };
      };
      userDirs = {
        enable = true;
        createDirectories = true;
        download = "${config.home.homeDirectory}/Downloads";
        documents = "${config.home.homeDirectory}/Documents";
        pictures = "${config.home.homeDirectory}/Pictures";
        videos = "${config.home.homeDirectory}/Videos";
        music = "${config.home.homeDirectory}/Music";
      };
    };
  };
}
