{
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

      communityPlugins = [
        (pkgs.stdenvNoCC.mkDerivation rec {
          pname = "obsidian-excalidraw-plugin";
          version = "2.25.2";

          manifestJson = pkgs.fetchurl {
            url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/${version}/manifest.json";
            sha256 = "19xlw8520p9lyljvnwyp0bskmb8pf5a6wd5nfifdgfy3m2sfl94c";
          };
          mainJs = pkgs.fetchurl {
            url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/${version}/main.js";
            sha256 = "0g3mkwy02yvbmzbwxcfanp705npndf976a0fvimn0sa3v7i6s0bf";
          };
          stylesCss = pkgs.fetchurl {
            url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/${version}/styles.css";
            sha256 = "0sc9v5ngzxj0g8i6dbmg44ssz7zpxin2rwkahmcyr09mxqzi2si3";
          };

          dontUnpack = true;
          installPhase = ''
            mkdir -p $out
            cp ${manifestJson} $out/manifest.json
            cp ${mainJs} $out/main.js
            cp ${stylesCss} $out/styles.css
          '';
        })
      ];

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
