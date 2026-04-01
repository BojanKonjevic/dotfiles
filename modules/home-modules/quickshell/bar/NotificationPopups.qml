import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: root

    required property NotificationServer server

    anchors {
        top: true
        right: true
    }
    margins.top: 36
    implicitWidth: 380
    implicitHeight: notifColumn.implicitHeight + 16
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true

    Column {
        id: notifColumn
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 8
            rightMargin: 8
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
