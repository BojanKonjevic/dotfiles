import QtQuick
import Quickshell.Hyprland

Rectangle {
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

    implicitWidth: 32
    implicitHeight: 28

    color: (isActive || hovered) ? Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.6) : "transparent"

    Rectangle {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        height: 2
        color: Colours.mauve
        visible: btn.isActive
    }

    Text {
        anchors.centerIn: parent
        text: btn.wsId.toString()
        font.family: Colours.fontFamily
        font.pixelSize: 18
        font.weight: Font.Black
        color: btn.isActive ? Colours.mauve : btn.isOccupied ? Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.75) : Qt.rgba(Colours.overlay2.r, Colours.overlay2.g, Colours.overlay2.b, 0.6)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: btn.hovered = true
        onExited: btn.hovered = false
        onClicked: Hyprland.dispatch("workspace " + btn.wsId)
    }
}
