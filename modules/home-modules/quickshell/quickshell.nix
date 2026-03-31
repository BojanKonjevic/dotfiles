{...}: {
  flake.homeModules.quickshell = {
    quickshell,
    theme,
    pkgs,
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
  in {
    home.packages = [
      quickshell
      (pkgs.writeShellScriptBin "power-menu" "qs -c powermenu")
      (pkgs.writeShellScriptBin "qs-cpu" ''
        awk '
          NR==1 { u=$2+$4; t=$2+$3+$4+$5 }
          NR==2 { print int(($2+$4-u)/($2+$3+$4+$5-t)*100) }
        ' <(grep "^cpu " /proc/stat) <(sleep 0.3; grep "^cpu " /proc/stat)
      '')
      (pkgs.writeShellScriptBin "qs-mem" ''
        awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print int((t-a)/t*100)}' /proc/meminfo
      '')
      (pkgs.writeShellScriptBin "qs-net" ''
        nmcli -t -f TYPE,STATE dev status 2>/dev/null \
          | awk -F: '$2=="connected" {print $1; exit}'
      '')
      (pkgs.writeShellScriptBin "qs-mic" ''
        wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -c MUTED
      '')
    ];

    # ── Powermenu ──────────────────────────────────────────────────────────────
    xdg.configFile."quickshell/powermenu/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/powermenu/qmldir".source = ./powermenu/qmldir;
    xdg.configFile."quickshell/powermenu/shell.qml".source = ./powermenu/shell.qml;
    xdg.configFile."quickshell/powermenu/PowerMenu.qml".source = ./powermenu/PowerMenu.qml;
    xdg.configFile."quickshell/powermenu/PowerButton.qml".source = ./powermenu/PowerButton.qml;

    # ── Bar ───────────────────────────────────────────────────────────────────
    xdg.configFile."quickshell/bar/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/bar/qmldir".source = ./bar/qmldir;
    xdg.configFile."quickshell/bar/shell.qml".source = ./bar/shell.qml;
    xdg.configFile."quickshell/bar/Bar.qml".source = ./bar/Bar.qml;
    xdg.configFile."quickshell/bar/WorkspaceButton.qml".source = ./bar/WorkspaceButton.qml;
    xdg.configFile."quickshell/bar/NotificationPopups.qml".source = ./bar/NotificationPopups.qml;
    xdg.configFile."quickshell/bar/NotificationPopup.qml".source = ./bar/NotificationPopup.qml;
  };
}
