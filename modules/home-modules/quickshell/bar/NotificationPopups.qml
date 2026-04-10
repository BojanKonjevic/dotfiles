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
    margins.left: Colours.notifPopupMargin
    implicitWidth: Colours.notifPopupW + Colours.spacingMd
    implicitHeight: notifColumn.implicitHeight + Colours.spacingLg
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true

    Column {
        id: notifColumn
        anchors {
            bottom: parent.bottom
            left: parent.left
            bottomMargin: Colours.spacingXs + Colours.spacingXs + 2
            leftMargin: Colours.spacingXs + Colours.spacingXs + 2
        }
        width: Colours.notifPopupW
        spacing: Colours.spacingXs + Colours.spacingXs + 2

        Repeater {
            model: root.server.trackedNotifications
            delegate: NotificationPopup {
                required property var modelData
                notification: modelData
                width: Colours.notifPopupW
            }
        }
    }
}
