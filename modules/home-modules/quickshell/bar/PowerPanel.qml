import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var state_

    anchors {
        bottom: true
        left: true
    }
    margins.left: 48

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    implicitWidth: state_.powerOpen ? 220 : 0
    implicitHeight: state_.powerOpen ? 200 : 0

    HoverHandler {
        id: panelHover
        onHoveredChanged: {
            root.state_.powerPanelHovered = hovered;
            if (!hovered)
                root.state_.powerOpen = false;
        }
    }

    Rectangle {
        id: content
        anchors {
            bottom: parent.bottom
            left: parent.left
        }
        width: 200
        height: state_.powerOpen ? column.implicitHeight + 24 : 0
        radius: Colours.radiusPanel
        color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, Colours.opacityPanel)
        border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacityBorder)
        border.width: 1
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        opacity: state_.powerOpen ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }

        ColumnLayout {
            id: column
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 4

            Text {
                text: " Power"
                font.family: Colours.fontFamily
                font.pixelSize: 16
                font.weight: Font.Bold
                color: Colours.red
                Layout.bottomMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                Layout.bottomMargin: 2
            }

            PowerPanelButton {
                icon: "󰌾"
                label: "Lock"
                onTriggered: {
                    root.state_.powerOpen = false;
                    Quickshell.execDetached(["hyprlock"]);
                }
            }

            PowerPanelButton {
                icon: "󰜉"
                label: "Reboot"
                onTriggered: {
                    root.state_.powerOpen = false;
                    Quickshell.execDetached(["systemctl", "reboot"]);
                }
            }

            PowerPanelButton {
                icon: "󰐥"
                label: "Power Off"
                onTriggered: {
                    root.state_.powerOpen = false;
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                }
            }
        }
    }
}
