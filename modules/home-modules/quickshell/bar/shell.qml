import Quickshell
import Quickshell.Services.Notifications
import QtQuick

ShellRoot {
    id: root

    NotificationServer {
        id: notifServer
        keepOnReload: true
        onNotification: function (notif) {
            notif.tracked = true;
        }
    }

    QtObject {
        id: barState
        property bool powerOpen: false
        property bool powerPanelHovered: false
        property bool dateTimeOpen: false
        property bool dateTimePanelHovered: false
        property var weatherPanel: null
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {
            required property var modelData
            screen: modelData
            state_: barState
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: NotificationPopups {
            required property var modelData
            screen: modelData
            server: notifServer
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: PowerPanel {
            required property var modelData
            screen: modelData
            state_: barState
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: DateTimePanel {
            required property var modelData
            screen: modelData
            state_: barState
        }
    }
}
