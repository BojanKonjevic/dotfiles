{...}: {
  flake.homeModules.quickshell = {
    quickshell,
    lib,
    theme,
    pkgs,
    userConfig,
    ...
  }: let
    coloursQml = ''
      pragma Singleton
      import QtQuick

      QtObject {
        // ── Colors ────────────────────────────────────────────────────────────
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

        // ── Typography ────────────────────────────────────────────────────────
        readonly property string fontFamily: "${theme.fontName}"

        // ── Border radii ──────────────────────────────────────────────────────
        readonly property int radiusPanel:      ${toString theme.radiusPanel}
        readonly property int radiusPopup:      ${toString theme.radiusPopup}
        readonly property int radiusTile:       ${toString theme.radiusTile}
        readonly property int radiusRow:        ${toString theme.radiusRow}
        readonly property int radiusSmall:      ${toString theme.radiusSmall}

        // ── Opacity ───────────────────────────────────────────────────────────
        readonly property real opacityPanel:     ${toString theme.opacityPanel}
        readonly property real opacityBar:       ${toString theme.opacityBar}
        readonly property real opacityOverlay:   ${toString theme.opacityOverlay}
        readonly property real opacityBorder:    ${toString theme.opacityBorder}
        readonly property real opacitySeparator: ${toString theme.opacitySeparator}

        // ── Layout ────────────────────────────────────────────────────────────
        readonly property int barWidth:         ${toString theme.barWidth}
        readonly property int panelDateTime:    ${toString theme.panelDateTime}
        readonly property int panelMediaAudio:  ${toString theme.panelMediaAudio}
        readonly property int panelNotif:       ${toString theme.panelNotif}
        readonly property int panelPower:       ${toString theme.panelPower}
        readonly property int popupLauncher:    ${toString theme.popupLauncher}
        readonly property int popupLauncherH:   ${toString theme.popupLauncherH}
        readonly property int popupClipText:    ${toString theme.popupClipText}
        readonly property int popupClipTextH:   ${toString theme.popupClipTextH}
        readonly property int popupClipImg:     ${toString theme.popupClipImg}
        readonly property int popupClipImgH:    ${toString theme.popupClipImgH}
        readonly property int popupWallpaper:   ${toString theme.popupWallpaper}
        readonly property int popupWallpaperH:  ${toString theme.popupWallpaperH}

        // ── Font sizes ────────────────────────────────────────────────────────
        readonly property int fontSizeXs:  ${toString theme.fontSizeXs}
        readonly property int fontSizeSm:  ${toString theme.fontSizeSm}
        readonly property int fontSizeMd:  ${toString theme.fontSizeMd}
        readonly property int fontSizeLg:  ${toString theme.fontSizeLg}
        readonly property int fontSizeXl:  ${toString theme.fontSizeXl}
        readonly property int fontSize2Xl: ${toString theme.fontSize2Xl}
        readonly property int fontSize3Xl: ${toString theme.fontSize3Xl}

        // ── Icon sizes ────────────────────────────────────────────────────────
        readonly property int iconSizeSm: ${toString theme.iconSizeSm}
        readonly property int iconSizeMd: ${toString theme.iconSizeMd}
        readonly property int iconSizeLg: ${toString theme.iconSizeLg}
        readonly property int iconSizeXl: ${toString theme.iconSizeXl}

        // ── Spacing ───────────────────────────────────────────────────────────
        readonly property int spacingXs: ${toString theme.spacingXs}
        readonly property int spacingSm: ${toString theme.spacingSm}
        readonly property int spacingMd: ${toString theme.spacingMd}
        readonly property int spacingLg: ${toString theme.spacingLg}
        readonly property int spacingXl: ${toString theme.spacingXl}

        // ── Misc element sizes ────────────────────────────────────────────────
        readonly property int workspaceBtnH:    ${toString theme.workspaceBtnH}
        readonly property int mediaArtSize:     ${toString theme.mediaArtSize}
        readonly property int sliderThumb:      ${toString theme.sliderThumb}
        readonly property int sliderTrackH:     ${toString theme.sliderTrackH}
        readonly property int progressH:        ${toString theme.progressH}
        readonly property int notifPopupW:      ${toString theme.notifPopupW}
        readonly property int notifPopupMargin: ${toString theme.notifPopupMargin}
        readonly property int powerBtnH:        ${toString theme.powerBtnH}
        readonly property int cavaBars:         ${toString theme.cavaBars}
      }
    '';

    mkScript = name: file: env:
      pkgs.writeShellScriptBin name (
        lib.concatStringsSep "\n"
        (lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}") env)
        + "\n"
        + builtins.readFile ./qs-scripts/${file}
      );
  in {
    home.packages = [
      pkgs.playerctl
      quickshell
      pkgs.wl-clipboard
      pkgs.cliphist
      pkgs.awww
      pkgs.pulseaudio
      pkgs.pipewire

      # ── Bar helpers ──────────────────────────────────────────────────────
      (mkScript "qs-cpu" "qs-cpu.sh" {})
      (mkScript "qs-mem" "qs-mem.sh" {})
      (mkScript "qs-audio-set" "qs-audio-set.sh" {})
      (mkScript "qs-audio-monitor" "qs-audio-monitor.sh" {})
      (mkScript "qs-net-monitor" "qs-net-monitor.sh" {})
      (mkScript "qs-clip-copy-text" "qs-clip-copy-text.sh" {})
      (mkScript "qs-clip-copy-img" "qs-clip-copy-img.sh" {})
      (mkScript "qs-clip-clear-text" "qs-clip-clear-text.sh" {})
      (mkScript "qs-clip-clear-img" "qs-clip-clear-img.sh" {})
      (mkScript "qs-clip-images" "qs-clip-images.sh" {})
      (mkScript "qs-cava-bar" "qs-cava-bar.sh" {
        CAVA_CONFIG = "${userConfig.homeDirectory}/.config/cava/cava-bar.conf";
      })
      (mkScript "qs-wallpapers" "qs-wallpapers.sh" {
        WALLPAPER_DIR = userConfig.wallpaperDir;
      })
      (mkScript "qs-setwall" "qs-setwall.sh" {
        WALLPAPER_DIR = userConfig.wallpaperDir;
      })
    ];

    # ── Bar ───────────────────────────────────────────────────────────────────
    xdg.configFile."quickshell/bar/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/bar/qmldir".source = ./bar/qmldir;
    xdg.configFile."quickshell/bar/shell.qml".source = ./bar/shell.qml;
    xdg.configFile."quickshell/bar/Bar.qml".source = ./bar/Bar.qml;
    xdg.configFile."quickshell/bar/WorkspaceButton.qml".source = ./bar/WorkspaceButton.qml;
    xdg.configFile."quickshell/bar/NotificationPopups.qml".source = ./bar/NotificationPopups.qml;
    xdg.configFile."quickshell/bar/NotificationPopup.qml".source = ./bar/NotificationPopup.qml;
    xdg.configFile."quickshell/bar/NotificationPanel.qml".source = ./bar/NotificationPanel.qml;
    xdg.configFile."quickshell/bar/PowerPanel.qml".source = ./bar/PowerPanel.qml;
    xdg.configFile."quickshell/bar/PowerPanelButton.qml".source = ./bar/PowerPanelButton.qml;
    xdg.configFile."quickshell/bar/DateTimePanel.qml".source = ./bar/DateTimePanel.qml;
    xdg.configFile."cava/cava-bar.conf".text = ''
      [general]
      bars = ${toString theme.cavaBars}
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
