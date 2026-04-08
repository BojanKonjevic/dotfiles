{...}: {
  flake.homeModules.quickshell = {
    quickshell,
    theme,
    pkgs,
    userConfig,
    ...
  }: let
    coloursQml = ''
      pragma Singleton
      import QtQuick

      QtObject {
        readonly property color base:      "${theme.base}"
        readonly property color mantle:    "${theme.mantle}"
        readonly property color crust:     "${theme.crust}"
        readonly property color surface0:  "${theme.surface0}"
        readonly property color surface1:  "${theme.surface1}"
        readonly property color surface2:  "${theme.surface2}"
        readonly property color overlay0:  "${theme.overlay0}"
        readonly property color overlay1:  "${theme.overlay1}"
        readonly property color overlay2:  "${theme.overlay2}"
        readonly property color subtext0:  "${theme.subtext0}"
        readonly property color subtext1:  "${theme.subtext1}"
        readonly property color text:      "${theme.text}"
        readonly property color rosewater: "${theme.rosewater}"
        readonly property color flamingo:  "${theme.flamingo}"
        readonly property color pink:      "${theme.pink}"
        readonly property color mauve:     "${theme.mauve}"
        readonly property color red:       "${theme.red}"
        readonly property color maroon:    "${theme.maroon}"
        readonly property color peach:     "${theme.peach}"
        readonly property color yellow:    "${theme.yellow}"
        readonly property color green:     "${theme.green}"
        readonly property color teal:      "${theme.teal}"
        readonly property color sky:       "${theme.sky}"
        readonly property color sapphire:  "${theme.sapphire}"
        readonly property color blue:      "${theme.blue}"
        readonly property color lavender:  "${theme.lavender}"

        readonly property string fontFamily: "${theme.fontName}"
      }
    '';

    # ── Script helpers ────────────────────────────────────────────────────────
    mkPure = name: file:
      pkgs.writeShellScriptBin name (builtins.readFile ./qs-scripts/${file});
    mkInterp = name: file: args:
      pkgs.writeShellScriptBin name (import ./qs-scripts/${file} args);
  in {
    home.packages = [
      pkgs.playerctl
      quickshell
      pkgs.wl-clipboard
      pkgs.cliphist
      pkgs.awww

      # ── Bar helpers ──────────────────────────────────────────────────────
      (mkPure "qs-cpu" "qs-cpu.sh")
      (mkPure "qs-mem" "qs-mem.sh")
      (mkPure "qs-net" "qs-net.sh")
      (mkPure "qs-mic" "qs-mic.sh")
      (mkInterp "qs-cava-bar" "qs-cava-bar.sh" {inherit pkgs userConfig;})
      (mkInterp "qs-audio" "qs-audio.sh" {inherit pkgs;})
      (mkPure "qs-audio-set" "qs-audio-set.sh")

      # ── Clipboard helpers ────────────────────────────────────────────────
      (mkPure "qs-clip-copy-text" "qs-clip-copy-text.sh")
      (mkPure "qs-clip-copy-img" "qs-clip-copy-img.sh")
      (mkPure "qs-clip-clear-text" "qs-clip-clear-text.sh")
      (mkPure "qs-clip-clear-img" "qs-clip-clear-img.sh")
      (mkPure "qs-clip-images" "qs-clip-images.sh")

      # ── Wallpaper helpers ────────────────────────────────────────────────
      (mkInterp "qs-wallpapers" "qs-wallpapers.sh" {inherit userConfig;})
      (mkInterp "qs-setwall" "qs-setwall.sh" {inherit userConfig;})
    ];

    # ── Bar ───────────────────────────────────────────────────────────────────
    xdg.configFile."quickshell/bar/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/bar/qmldir".source = ./bar/qmldir;
    xdg.configFile."quickshell/bar/shell.qml".source = ./bar/shell.qml;
    xdg.configFile."quickshell/bar/Bar.qml".source = ./bar/Bar.qml;
    xdg.configFile."quickshell/bar/WorkspaceButton.qml".source = ./bar/WorkspaceButton.qml;
    xdg.configFile."quickshell/bar/NotificationPopups.qml".source = ./bar/NotificationPopups.qml;
    xdg.configFile."quickshell/bar/NotificationPopup.qml".source = ./bar/NotificationPopup.qml;
    xdg.configFile."quickshell/bar/PowerPanel.qml".source = ./bar/PowerPanel.qml;
    xdg.configFile."quickshell/bar/PowerPanelButton.qml".source = ./bar/PowerPanelButton.qml;
    xdg.configFile."quickshell/bar/DateTimePanel.qml".source = ./bar/DateTimePanel.qml;
    xdg.configFile."cava/cava-bar.conf".text = ''
      [general]
      bars = 20
      sleep_timer = 5

      [input]
      method = pipewire

      [output]
      method = raw
      raw_target = /dev/stdout
      data_format = ascii
      ascii_max_range = 15
    '';
    xdg.configFile."quickshell/bar/MediaAudioPanel.qml".source = ./bar/MediaAudioPanel.qml;

    # ── Launcher ──────────────────────────────────────────────────────────────
    xdg.configFile."quickshell/launcher/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/launcher/qmldir".source = ./launcher/qmldir;
    xdg.configFile."quickshell/launcher/shell.qml".source = ./launcher/shell.qml;
    xdg.configFile."quickshell/launcher/Launcher.qml".source = ./launcher/Launcher.qml;
    xdg.configFile."quickshell/launcher/AppEntry.qml".source = ./launcher/AppEntry.qml;

    # ── Clipboard text ────────────────────────────────────────────────────────
    xdg.configFile."quickshell/clip-text/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/clip-text/qmldir".source = ./clip-text/qmldir;
    xdg.configFile."quickshell/clip-text/shell.qml".source = ./clip-text/shell.qml;
    xdg.configFile."quickshell/clip-text/ClipText.qml".source = ./clip-text/ClipText.qml;

    # ── Clipboard image ───────────────────────────────────────────────────────
    xdg.configFile."quickshell/clip-img/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/clip-img/qmldir".source = ./clip-img/qmldir;
    xdg.configFile."quickshell/clip-img/shell.qml".source = ./clip-img/shell.qml;
    xdg.configFile."quickshell/clip-img/ClipImage.qml".source = ./clip-img/ClipImage.qml;

    # ── Wallpaper ─────────────────────────────────────────────────────────────
    xdg.configFile."quickshell/wallpaper/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/wallpaper/qmldir".source = ./wallpaper/qmldir;
    xdg.configFile."quickshell/wallpaper/shell.qml".source = ./wallpaper/shell.qml;
    xdg.configFile."quickshell/wallpaper/WallpaperPicker.qml".source = ./wallpaper/WallpaperPicker.qml;
  };
}
