import QtQuick
import Quickshell.Hyprland

Item {
    id: btn
    required property int wsId

    property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
    property bool isOccupied: {
        var ws = Hyprland.workspaces.values;
        for (var i = 0; i < ws.length; i++) {
            if (ws[i].id === wsId)
                return true;
        }
        return false;
    }
    property bool hovered: false

    visible: wsId <= 5 || isActive || isOccupied

    implicitWidth: 48
    implicitHeight: 22

    Rectangle {
        anchors.centerIn: parent
        width: btn.isActive ? 34 : (btn.hovered ? 30 : 26)
        height: 20
        radius: 4
        color: btn.isActive ? Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.18) : btn.hovered ? Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5) : "transparent"

        Behavior on width {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        // Left accent stripe for active
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            width: 2
            radius: 1
            color: Colours.mauve
            visible: btn.isActive
        }

        Text {
            anchors.centerIn: parent
            text: btn.wsId.toString()
            font.family: Colours.fontFamily
            font.pixelSize: 11
            font.weight: btn.isActive ? Font.Black : Font.Medium
            color: btn.isActive ? Colours.mauve : btn.isOccupied ? Qt.rgba(Colours.text.r, Colours.text.g, Colours.text.b, 0.75) : Qt.rgba(Colours.overlay1.r, Colours.overlay1.g, Colours.overlay1.b, 0.5)

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }

        // Occupied dot (when not active)
        Rectangle {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 2
            }
            width: 3
            height: 3
            radius: 2
            color: Colours.mauve
            opacity: 0.6
            visible: btn.isOccupied && !btn.isActive
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: btn.hovered = true
        onExited: btn.hovered = false
        onClicked: Hyprland.dispatch("workspace " + btn.wsId)
        cursorShape: Qt.PointingHandCursor
    }
}
