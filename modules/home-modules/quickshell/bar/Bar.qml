import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: root

    required property var state_

    anchors {
        top: true
        left: true
        bottom: true
    }
    implicitWidth: 56
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.85)

    property bool hasMedia: root.state_.mediaStatus !== "Stopped" && root.state_.mediaTitle !== ""

    property string clockHour: Qt.formatDateTime(new Date(), "hh")
    property string clockMin: Qt.formatDateTime(new Date(), "mm")
    property string clockDate: Qt.formatDateTime(new Date(), "dd MMM")
    property string weatherText: ""
    property int cpuUsage: 0
    property int memUsage: 0
    property string netType: ""
    property string activeSubmap: root.state_.activeSubmap
    property int notifCount: root.state_.notifCount

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.clockHour = Qt.formatDateTime(new Date(), "hh");
            root.clockMin = Qt.formatDateTime(new Date(), "mm");
            root.clockDate = Qt.formatDateTime(new Date(), "dd MMM");
        }
    }

    Process {
        id: weatherProc
        command: ["weather", "--bar"]
        stdout: SplitParser {
            onRead: function (data) {
                try {
                    root.weatherText = JSON.parse(data).text || "";
                } catch (_) {}
            }
        }
    }
    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!weatherProc.running)
            weatherProc.running = true
    }

    Process {
        id: cpuProc
        command: ["qs-cpu"]
        stdout: SplitParser {
            onRead: function (data) {
                root.cpuUsage = parseInt(data) || 0;
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!cpuProc.running)
            cpuProc.running = true
    }

    Process {
        id: memProc
        command: ["qs-mem"]
        stdout: SplitParser {
            onRead: function (data) {
                root.memUsage = parseInt(data) || 0;
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!memProc.running)
            memProc.running = true
    }

    Process {
        id: netProc
        command: ["qs-net"]
        stdout: SplitParser {
            onRead: function (data) {
                root.netType = data.trim();
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!netProc.running)
            netProc.running = true
    }

    Item {
        anchors.fill: parent

        // Right edge separator line
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: 1
            color: Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.35)
        }

        ColumnLayout {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            spacing: 0

            // ── Top section ─────────────────────────────────────────────────
            // Clock / date
            Item {
                id: clockItem
                Layout.fillWidth: true
                implicitHeight: clockCol.implicitHeight + 20

                ColumnLayout {
                    id: clockCol
                    anchors.centerIn: parent
                    spacing: -4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.clockHour
                        color: Colours.mauve
                        font.family: Colours.fontFamily
                        font.pixelSize: 26
                        font.weight: Font.Black
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.clockMin
                        color: Colours.lavender
                        font.family: Colours.fontFamily
                        font.pixelSize: 26
                        font.weight: Font.Black
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.clockDate
                        color: Colours.subtext0
                        font.family: Colours.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        Layout.topMargin: 6
                    }
                }

                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) {
                            root.state_.dateTimeOpen = true;
                        } else {
                            dateTimeHideTimer.restart();
                        }
                    }
                }

                Timer {
                    id: dateTimeHideTimer
                    interval: 300
                    onTriggered: {
                        if (!root.state_.dateTimePanelHovered)
                            root.state_.dateTimeOpen = false;
                    }
                }
            }

            // ── Workspaces ───────────────────────────────────────────────────
            Repeater {
                model: 10
                delegate: WorkspaceButton {
                    required property int index
                    wsId: index + 1
                }
            }

            // ── Media ────────────────────────────────────────────────────────
            Item {
                id: mediaItem
                Layout.fillWidth: true
                implicitHeight: 40

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    color: root.hasMedia ? Colours.blue : Colours.overlay0
                    font.family: Colours.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.Black
                }

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) {
                            var mapped = mediaItem.mapToGlobal(mediaItem.width, mediaItem.height / 2);
                            root.state_.mediaAudioX = mapped.x;
                            root.state_.mediaAudioY = mapped.y;
                            root.state_.mediaAudioOpen = true;
                        } else {
                            mediaAudioHideTimer.restart();
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // ── Bottom section ───────────────────────────────────────────────

            // Submap indicator
            Item {
                id: submapItem
                Layout.fillWidth: true
                implicitHeight: 40
                visible: root.activeSubmap !== ""

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰩨"
                    color: Colours.red
                    font.family: Colours.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.Black
                }
            }

            // Notifications
            Item {
                id: notifItem
                Layout.fillWidth: true
                implicitHeight: 40
                visible: root.notifCount > 0

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    color: root.state_.notifPanelOpen ? Colours.mauve : Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.7)
                    font.family: Colours.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.Black
                }

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) {
                            root.state_.notifPanelOpen = true;
                        } else {
                            notifHideTimer.restart();
                        }
                    }
                }

                Timer {
                    id: notifHideTimer
                    interval: 300
                    onTriggered: {
                        if (!root.state_.notifPanelHovered)
                            root.state_.notifPanelOpen = false;
                    }
                }
            }

            // CPU
            Item {
                Layout.fillWidth: true
                implicitHeight: 50

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰍛"
                        color: Colours.peach
                        font.family: Colours.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Black
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.cpuUsage + "%"
                        color: Colours.peach
                        font.family: Colours.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }
            }

            // MEM
            Item {
                Layout.fillWidth: true
                implicitHeight: 50

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰾆"
                        color: Colours.blue
                        font.family: Colours.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Black
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.memUsage + "%"
                        color: Colours.blue
                        font.family: Colours.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }
            }

            // Network
            Item {
                Layout.fillWidth: true
                implicitHeight: 40

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                Text {
                    anchors.centerIn: parent
                    text: root.netType === "wifi" ? "󰤨" : root.netType === "ethernet" ? "󰈀" : "󰤭"
                    color: root.netType === "" ? Colours.overlay0 : Colours.sky
                    font.family: Colours.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.Black
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached(["nm-connection-editor"])
                    }
                }
            }

            // Power button
            Item {
                id: powerItem
                Layout.fillWidth: true
                implicitHeight: 44

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                Text {
                    anchors.centerIn: parent
                    text: "⏻"
                    font.family: Colours.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.Black
                    color: root.state_.powerOpen ? Colours.red : Qt.rgba(Colours.overlay1.r, Colours.overlay1.g, Colours.overlay1.b, 0.8)
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.state_.powerOpen = true
                    onExited: powerHideTimer.restart()
                }

                Timer {
                    id: powerHideTimer
                    interval: 300
                    onTriggered: {
                        if (!root.state_.powerPanelHovered)
                            root.state_.powerOpen = false;
                    }
                }
            }
        }

        Timer {
            id: mediaAudioHideTimer
            interval: 300
            onTriggered: {
                if (!root.state_.mediaAudioPanelHovered)
                    root.state_.mediaAudioOpen = false;
            }
        }
    }
}
