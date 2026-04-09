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
    implicitWidth: 48
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.90)

    property bool hasMedia: root.state_.mediaStatus !== "Stopped" && root.state_.mediaTitle !== ""

    property string clockHour: Qt.formatDateTime(new Date(), "hh")
    property string clockMin: Qt.formatDateTime(new Date(), "mm")
    property int cpuUsage: 0
    property int memUsage: 0
    property string netType: ""
    property string activeSubmap: root.state_.activeSubmap
    property int notifCount: root.state_.notifCount
    property int micMuted: 0

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.clockHour = Qt.formatDateTime(new Date(), "hh");
            root.clockMin = Qt.formatDateTime(new Date(), "mm");
        }
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

    Process {
        id: micProc
        command: ["qs-mic"]
        stdout: SplitParser {
            onRead: function (data) {
                root.micMuted = parseInt(data) || 0;
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!micProc.running)
            micProc.running = true
    }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: 1
            color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.8)
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Clock ────────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: clockCol.implicitHeight + 22

                ColumnLayout {
                    id: clockCol
                    anchors.centerIn: parent
                    spacing: -3

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.clockHour
                        color: Colours.mauve
                        font.family: Colours.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Black
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.clockMin
                        color: Colours.blue
                        font.family: Colours.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Black
                    }
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

                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        leftMargin: 12
                        rightMargin: 12
                    }
                    height: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.25)
                }
            }

            // ── Workspaces ───────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: wsCol.implicitHeight + 14

                Column {
                    id: wsCol
                    anchors.centerIn: parent
                    spacing: 2

                    Repeater {
                        model: 10
                        delegate: WorkspaceButton {
                            required property int index
                            wsId: index + 1
                        }
                    }
                }
            }

            // ── Divider ──────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.25)
            }

            // ── CPU bar ──────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 32

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰍛"
                        color: Qt.rgba(Colours.peach.r, Colours.peach.g, Colours.peach.b, 0.4 + root.cpuUsage / 100 * 0.6)
                        font.family: Colours.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Black
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 26
                        height: 2
                        radius: 1
                        color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)

                        Rectangle {
                            width: parent.width * (root.cpuUsage / 100)
                            height: parent.height
                            radius: parent.radius
                            color: Colours.peach
                            Behavior on width {
                                NumberAnimation {
                                    duration: 500
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }

            // ── MEM bar ──────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 32

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰾆"
                        color: Qt.rgba(Colours.blue.r, Colours.blue.g, Colours.blue.b, 0.4 + root.memUsage / 100 * 0.6)
                        font.family: Colours.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Black
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 26
                        height: 2
                        radius: 1
                        color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)

                        Rectangle {
                            width: parent.width * (root.memUsage / 100)
                            height: parent.height
                            radius: parent.radius
                            color: Colours.blue
                            Behavior on width {
                                NumberAnimation {
                                    duration: 500
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }

            // ── Spacer ───────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // ── Submap (only when active) ─────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 32
                visible: root.activeSubmap !== ""

                Text {
                    anchors.centerIn: parent
                    text: "󰩨"
                    color: Colours.red
                    font.family: Colours.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.Black
                }
            }

            // ── Media ────────────────────────────────────────────────────────
            Item {
                id: mediaItem
                Layout.fillWidth: true
                implicitHeight: 34

                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    color: root.hasMedia ? Colours.blue : Qt.rgba(Colours.overlay0.r, Colours.overlay0.g, Colours.overlay0.b, 0.5)
                    font.family: Colours.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.Black

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
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

            // ── Divider ──────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.25)
            }

            // ── Notifications ─────────────────────────────────────────────────
            Item {
                id: notifItem
                Layout.fillWidth: true
                implicitHeight: 34
                visible: root.notifCount > 0

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    color: root.state_.notifPanelOpen ? Colours.mauve : Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.6)
                    font.family: Colours.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.Black
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        horizontalCenterOffset: 7
                        topMargin: 7
                    }
                    width: 5
                    height: 5
                    radius: 3
                    color: Colours.mauve
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

            // ── Mic ──────────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 34

                Text {
                    anchors.centerIn: parent
                    text: root.micMuted === 1 ? "󰍭" : "󰍬"
                    color: root.micMuted === 1 ? Colours.red : Colours.green
                    font.family: Colours.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.Black

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }
            }

            // ── Network ──────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 34

                Text {
                    anchors.centerIn: parent
                    text: root.netType === "wifi" ? "󰤨" : root.netType === "ethernet" ? "󰈀" : "󰤭"
                    color: root.netType === "" ? Qt.rgba(Colours.overlay0.r, Colours.overlay0.g, Colours.overlay0.b, 0.5) : Colours.sky
                    font.family: Colours.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.Black

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached(["nm-connection-editor"])
                    }
                }
            }

            // ── Power ─────────────────────────────────────────────────────────
            Item {
                id: powerItem
                Layout.fillWidth: true
                implicitHeight: 38
                Layout.bottomMargin: 4

                Text {
                    anchors.centerIn: parent
                    text: "⏻"
                    font.family: Colours.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.Black
                    color: root.state_.powerOpen ? Colours.red : Qt.rgba(Colours.overlay1.r, Colours.overlay1.g, Colours.overlay1.b, 0.7)

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
