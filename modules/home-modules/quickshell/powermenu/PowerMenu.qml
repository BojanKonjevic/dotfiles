import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    width: 260
    height: column.implicitHeight + 32
    radius: 14
    color: Colours.crust
    border.color: Colours.surface1
    border.width: 1

    MouseArea {
        anchors.fill: parent
    }

    ColumnLayout {
        id: column
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 16
        }
        spacing: 6

        Text {
            text: " Power"
            font.family: Colours.fontFamily
            font.pixelSize: 20
            color: Colours.red
            Layout.bottomMargin: 8
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.surface1
            opacity: 0.5
            Layout.bottomMargin: 6
        }

        PowerButton {
            icon: "󰌾"
            label: "Lock"
            onTriggered: {
                Quickshell.execDetached(["hyprlock"]);
                Qt.quit();
            }
        }
        PowerButton {
            icon: "󰜉"
            label: "Reboot"
            onTriggered: {
                Quickshell.execDetached(["systemctl", "reboot"]);
                Qt.quit();
            }
        }
        PowerButton {
            icon: "󰐥"
            label: "Power Off"
            onTriggered: {
                Quickshell.execDetached(["systemctl", "poweroff"]);
                Qt.quit();
            }
        }
    }
}
