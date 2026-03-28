{...}: {
  flake.homeModules.quickshell = {
    quickshell,
    theme,
    pkgs,
    ...
  }: {
    home.packages = [
      quickshell
      (pkgs.writeShellScriptBin "power-menu" ''
        qs -c powermenu
      '')
    ];

    xdg.configFile."quickshell/powermenu/Colours.qml".text = ''
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

    xdg.configFile."quickshell/powermenu/qmldir".source =
      ./powermenu/qmldir;
    xdg.configFile."quickshell/powermenu/shell.qml".source =
      ./powermenu/shell.qml;
    xdg.configFile."quickshell/powermenu/PowerMenu.qml".source =
      ./powermenu/PowerMenu.qml;
    xdg.configFile."quickshell/powermenu/PowerButton.qml".source =
      ./powermenu/PowerButton.qml;
  };
}
