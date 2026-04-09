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
        property real mediaAudioY: 0
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
        property bool micMuted: false
        property string netType: ""
        property int cpuUsage: 0
        property int memUsage: 0
        property var clearNotifs: function () {
            var notifs = notifServer.trackedNotifications.values;
            for (var i = notifs.length - 1; i >= 0; i--) {
                notifs[i].tracked = false;
            }
        }
    }

    // ── Media — event-driven via --follow ─────────────────────────────────────
    Process {
        id: mediaProc
        command: ["playerctl", "--follow", "metadata", "--format", '{"title":"{{title}}","artist":"{{artist}}","album":"{{album}}","art":"{{mpris:artUrl}}","status":"{{status}}","length":"{{mpris:length}}"}']
        running: true
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
            barState.mediaTitle = "";
            barState.mediaStatus = "Stopped";
            // restart after a short delay to handle playerctl having no player
            mediaRestartTimer.restart();
        }
    }

    Timer {
        id: mediaRestartTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (!mediaProc.running)
                mediaProc.running = true;
        }
    }

    // ── Media position — still polled (playerctl has no follow for position) ──
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
            if (!mediaPosProc.running)
                mediaPosProc.running = true;
        }
    }

    // ── Audio + Mic — event-driven via qs-audio-monitor ───────────────────────
    Process {
        id: audioProc
        command: ["qs-audio-monitor"]
        running: true
        stdout: SplitParser {
            onRead: function (data) {
                try {
                    var parsed = JSON.parse(data);
                    if (parsed.type === "audio") {
                        barState.audioData = parsed.data;
                    } else if (parsed.type === "mic") {
                        barState.micMuted = parsed.muted;
                    }
                } catch (_) {}
            }
        }
        onExited: function () {
            audioRestartTimer.restart();
        }
    }

    Timer {
        id: audioRestartTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!audioProc.running)
                audioProc.running = true;
        }
    }

    // ── Network — event-driven via nmcli monitor ──────────────────────────────
    Process {
        id: netProc
        command: ["qs-net-monitor"]
        running: true
        stdout: SplitParser {
            onRead: function (data) {
                barState.netType = data.trim();
            }
        }
        onExited: function () {
            netRestartTimer.restart();
        }
    }

    Timer {
        id: netRestartTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!netProc.running)
                netProc.running = true;
        }
    }

    // ── CPU + MEM — single shared 2s polling timer ────────────────────────────
    Process {
        id: cpuProc
        command: ["qs-cpu"]
        stdout: SplitParser {
            onRead: function (data) {
                barState.cpuUsage = parseInt(data) || 0;
            }
        }
    }

    Process {
        id: memProc
        command: ["qs-mem"]
        stdout: SplitParser {
            onRead: function (data) {
                barState.memUsage = parseInt(data) || 0;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!cpuProc.running)
                cpuProc.running = true;
            if (!memProc.running)
                memProc.running = true;
        }
    }

    // ── Hyprland submap ───────────────────────────────────────────────────────
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial" || event.name === "submap") {
                barState.activeSubmap = event.data === "" ? "" : event.data;
            }
        }
    }

    // ── Shell variants ────────────────────────────────────────────────────────
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
