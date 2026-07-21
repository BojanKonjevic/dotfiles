{
  config,
  lib,
  pkgs,
  theme,
  ...
}: let
  vaultPath = "Documents/Obsidian";
in {
  programs.obsidian = {
    enable = true;

    vaults.${vaultPath}.enable = true;

    defaultSettings = {
      app = {
        defaultViewMode = "source";
        livePreview = true;
      };

      appearance = {
        theme = "obsidian";
        cssTheme = "";
        baseFontSize = 16;
      };

      corePlugins = [
        "file-explorer"
        "global-search"
        "switcher"
        "graph"
        "backlink"
        "outgoing-link"
        "tag-pane"
        "page-preview"
        "templates"
        "note-composer"
        "command-palette"
        "editor-status"
        "markdown-importer"
        "outline"
        "word-count"
        "file-recovery"
      ];

      communityPlugins = [];

      cssSnippets = [
        {
          name = "catppuccin";
          text = ''
            .theme-dark {
              --background-primary: ${theme.base};
              --background-primary-alt: ${theme.mantle};
              --background-secondary: ${theme.mantle};
              --background-secondary-alt: ${theme.crust};
              --background-modifier-border: ${theme.surface0};
              --text-normal: ${theme.text};
              --text-muted: ${theme.subtext0};
              --text-accent: ${theme.mauve};
              --text-accent-hover: ${theme.mauve};
              --interactive-accent: ${theme.mauve};
              --interactive-accent-hover: ${theme.mauve};
              --tag-color: ${theme.blue};
            }
          '';
        }
      ];
    };
  };
}
