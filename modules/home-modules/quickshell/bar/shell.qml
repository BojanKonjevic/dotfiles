import Quickshell
import Quickshell.Services.Notifications

ShellRoot {
    NotificationServer {
        id: notifServer
        keepOnReload: true
        onNotification: function (notif) {
            notif.tracked = true;
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {
            required property var modelData
            screen: modelData
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
}
