import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    id: root

    NotificationServer {
        id: notifServer
        keepOnReload: true
        onNotification: function (notif) {
            notif.tracked = true;
            barState.notifCount += 1;
            notif.trackedChanged.connect(function () {
                if (!notif.tracked)
                    barState.notifCount = Math.max(0, barState.notifCount - 1);
            });
        }
    }

    QtObject {
        id: barState
        property bool powerOpen: false
        property bool powerPanelHovered: false
        property bool dateTimeOpen: false
        property bool dateTimePanelHovered: false
        property var weatherPanel: null
        property bool mediaAudioOpen: false
        property bool mediaAudioPanelHovered: false
        property real mediaAudioX: 0
        property bool notifPanelOpen: false
        property bool notifPanelHovered: false
        property string mediaTitle: ""
        property string mediaArtist: ""
        property string mediaAlbum: ""
        property string mediaArtUrl: ""
        property string mediaStatus: "Stopped"
        property real mediaPosition: 0
        property real mediaLength: 0
        property var audioData: null
        property string activeSubmap: ""
        property int notifCount: 0
        property var clearNotifs: function () {
            var notifs = notifServer.trackedNotifications.values;
            for (var i = notifs.length - 1; i >= 0; i--) {
                notifs[i].tracked = false;
            }
        }
    }

    Process {
        id: audioProc
        command: ["qs-audio"]
        stdout: SplitParser {
            onRead: function (data) {
                try {
                    barState.audioData = JSON.parse(data);
                } catch (_) {}
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!audioProc.running)
                audioProc.running = true;
        }
    }

    Process {
        id: mediaProc
        command: ["playerctl", "metadata", "--format", '{"title":"{{title}}","artist":"{{artist}}","album":"{{album}}","art":"{{mpris:artUrl}}","status":"{{status}}","length":"{{mpris:length}}"}']
        stdout: SplitParser {
            onRead: function (data) {
                try {
                    var m = JSON.parse(data);
                    barState.mediaTitle = m.title || "";
                    barState.mediaArtist = m.artist || "";
                    barState.mediaAlbum = m.album || "";
                    barState.mediaArtUrl = m.art || "";
                    barState.mediaStatus = m.status || "Stopped";
                    barState.mediaLength = parseFloat(m.length) / 1000000.0 || 0;
                } catch (_) {}
            }
        }
        onExited: function (code) {
            if (code !== 0) {
                barState.mediaTitle = "";
                barState.mediaStatus = "Stopped";
            }
        }
    }

    Process {
        id: mediaPosProc
        command: ["playerctl", "position"]
        stdout: SplitParser {
            onRead: function (data) {
                barState.mediaPosition = parseFloat(data) || 0;
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!mediaProc.running)
                mediaProc.running = true;
            if (!mediaPosProc.running)
                mediaPosProc.running = true;
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial" || event.name === "submap") {
                barState.activeSubmap = event.data === "" ? "" : event.data;
            }
        }
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
        delegate: MediaAudioPanel {
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
        delegate: NotificationPanel {
            required property var modelData
            screen: modelData
            state_: barState
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
