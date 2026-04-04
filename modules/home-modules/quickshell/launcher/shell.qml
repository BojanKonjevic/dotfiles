import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    PanelWindow {
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }
        }

        Launcher {
            anchors.centerIn: parent
        }
    }
}
