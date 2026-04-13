import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    id: root

    // ── Persistent notification history ───────────────────────────────────────
    // Written to $XDG_DATA_HOME/quickshell-bar/notifications.json
    // Each entry: { id, appName, appIcon, summary, body, time }

    property var notifHistory: []
    readonly property string notifFilePath: {
        var base = Quickshell.env("XDG_DATA_HOME");
        if (!base || base === "")
            base = Quickshell.env("HOME") + "/.local/share";
        return base + "/quickshell-bar/notifications.json";
    }

    // Maps notifServer notification id → history entry id
    // so the popup can call removeNotif with the right history id
    property var notifIdMap: ({})

    FileView {
        id: historyFile
        path: root.notifFilePath
        onLoaded: {
            try {
                var parsed = JSON.parse(historyFile.text());
                if (Array.isArray(parsed)) {
                    root.notifHistory = parsed;
                    barState.notifCount = parsed.length;
                }
            } catch (_) {
                root.notifHistory = [];
            }
        }
        onLoadFailed: {
            root.notifHistory = [];
        }
    }

    Process {
        id: saveProc
        property string payload: ""
        command: ["bash", "-c", "mkdir -p \"$(dirname \"$NOTIF_FILE\")\" && printf '%s' \"$PAYLOAD\" > \"$NOTIF_FILE\""]
        environment: ({
                "NOTIF_FILE": root.notifFilePath,
                "PAYLOAD": saveProc.payload
            })
    }

    function saveHistory() {
        saveProc.payload = JSON.stringify(root.notifHistory);
        if (!saveProc.running)
            saveProc.running = true;
    }

    function addToHistory(notif) {
        var historyId = Date.now() + "_" + Math.floor(Math.random() * 1000000);
        var entry = {
            id: historyId,
            appName: notif.appName || "",
            appIcon: notif.appIcon || "",
            summary: notif.summary || "",
            body: notif.body || "",
            time: Qt.formatDateTime(new Date(), "hh:mm")
        };
        // Store the mapping so the popup can find this history entry later
        var map = root.notifIdMap;
        map[notif.id] = historyId;
        root.notifIdMap = map;

        var h = [entry].concat(root.notifHistory);
        if (h.length > 50)
            h = h.slice(0, 50);
        root.notifHistory = h;
        barState.notifCount = root.notifHistory.length;
        saveHistory();
        return historyId;
    }

    function removeFromHistory(entryId) {
        root.notifHistory = root.notifHistory.filter(function (e) {
            return e.id !== entryId;
        });
        barState.notifCount = root.notifHistory.length;
        saveHistory();
    }

    function clearHistory() {
        root.notifHistory = [];
        barState.notifCount = 0;
        saveHistory();
    }

    Component.onCompleted: historyFile.reload()

    NotificationServer {
        id: notifServer
        keepOnReload: true
        onNotification: function (notif) {
            notif.tracked = true;
            root.addToHistory(notif);
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
        function closeAllPanels() {
            barState.dateTimeOpen = false;
            barState.mediaAudioOpen = false;
            barState.notifPanelOpen = false;
            barState.powerOpen = false;
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

    // ── Media position ────────────────────────────────────────────────────────
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

    // ── Audio + Mic ───────────────────────────────────────────────────────────
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

    // ── Network ───────────────────────────────────────────────────────────────
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

    // ── CPU + MEM ─────────────────────────────────────────────────────────────
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
            notifIdMap: root.notifIdMap
            onRemoveNotif: function (entryId) {
                root.removeFromHistory(entryId);
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: NotificationPanel {
            required property var modelData
            screen: modelData
            state_: barState
            notifHistory: root.notifHistory
            onRemoveNotif: function (entryId) {
                root.removeFromHistory(entryId);
            }
            onClearAllNotifs: root.clearHistory()
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
