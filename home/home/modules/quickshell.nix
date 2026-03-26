{
  quickshell,
  theme,
  ...
}: {
  home.packages = [quickshell];

  xdg.configFile."quickshell/powermenu/shell.qml".text = ''
    import Quickshell
    import Quickshell.Wayland
    import QtQuick
    import QtQuick.Layouts

    ShellRoot {
      id: root

      Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
      }

      PanelWindow {
        id: win
        anchors {
          top: true; bottom: true; left: true; right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true

        MouseArea {
          anchors.fill: parent
          onClicked: Qt.quit()
        }

        Rectangle {
          id: card
          width: 260
          height: column.implicitHeight + 32
          anchors.centerIn: parent
          color: "#11111b"
          radius: 14
          border.color: "#45475a"
          border.width: 1

          MouseArea { anchors.fill: parent }

          ColumnLayout {
            id: column
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors.margins: 16
            spacing: 6

            Text {
              text: " Power"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 20
              color: "#f38ba8"
              Layout.bottomMargin: 8
            }

            Rectangle {
              Layout.fillWidth: true
              height: 1
              color: "#45475a"
              opacity: 0.5
              Layout.bottomMargin: 6
            }

            PowerButton {
              icon: "󰌾"; label: "Lock"
              onTriggered: { Quickshell.execDetached(["hyprlock"]); Qt.quit() }
            }
            PowerButton {
              icon: "󰜉"; label: "Reboot"
              onTriggered: { Quickshell.execDetached(["systemctl", "reboot"]); Qt.quit() }
            }
            PowerButton {
              icon: "󰐥"; label: "Power Off"
              onTriggered: { Quickshell.execDetached(["systemctl", "poweroff"]); Qt.quit() }
            }
          }
        }
      }
    }
  '';

  xdg.configFile."quickshell/powermenu/PowerButton.qml".text = ''
    import QtQuick
    import QtQuick.Layouts

    Rectangle {
      id: btn
      property string icon: ""
      property string label: ""
      signal triggered

      Layout.fillWidth: true
      height: 44
      radius: 8
      color: "transparent"

      property bool hovered: false

      Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "#f38ba8"
        opacity: btn.hovered ? 0.18 : 0.0
        Behavior on opacity { NumberAnimation { duration: 80 } }
      }

      Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: "#f38ba8"
        border.width: 1
        opacity: btn.hovered ? 0.55 : 0.0
        Behavior on opacity { NumberAnimation { duration: 80 } }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: btn.hovered = true
        onExited: btn.hovered = false
        onClicked: btn.triggered()
        cursorShape: Qt.PointingHandCursor
      }

      RowLayout {
        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
        spacing: 12

        Text {
          text: btn.icon
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 18
          color: btn.hovered ? "#f38ba8" : "#a6adc8"
          Behavior on color { ColorAnimation { duration: 80 } }
        }

        Text {
          text: btn.label
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          color: btn.hovered ? "#f38ba8" : "#a6adc8"
          Layout.fillWidth: true
          Behavior on color { ColorAnimation { duration: 80 } }
        }
      }
    }
  '';
}
