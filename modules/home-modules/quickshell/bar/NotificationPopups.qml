import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: root

    required property NotificationServer server

    anchors {
        bottom: true
        left: true
    }
    margins.left: 56
    implicitWidth: 380
    implicitHeight: notifColumn.implicitHeight + 16
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true

    Column {
        id: notifColumn
        anchors {
            bottom: parent.bottom
            left: parent.left
            bottomMargin: 8
            leftMargin: 8
        }
        width: 364
        spacing: 8

        Repeater {
            model: root.server.trackedNotifications
            delegate: NotificationPopup {
                required property var modelData
                notification: modelData
                width: 364
            }
        }
    }
}
