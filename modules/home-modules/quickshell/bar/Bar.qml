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
        right: true
    }
    implicitHeight: 28
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, Colours.opacityBar)

    property bool hasMedia: root.state_.mediaStatus !== "Stopped" && root.state_.mediaTitle !== ""

    property string clockText: Qt.formatDateTime(new Date(), "dd dddd hh:mm AP")
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
        onTriggered: root.clockText = Qt.formatDateTime(new Date(), "dd dddd hh:mm AP")
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

        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: 1
            color: Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.35)
        }

        // ── Left ────────────────────────────────────────────────────────────
        RowLayout {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 4
            }
            spacing: 0

            Item {
                id: clockItem
                implicitWidth: clockLabel.implicitWidth + 16
                Layout.fillHeight: true

                Text {
                    id: clockLabel
                    anchors.centerIn: parent
                    text: root.clockText
                    color: Colours.mauve
                    font.family: Colours.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Black
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
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

            // ── Media (opens combined panel) ─────────────────────────────────
            Item {
                id: mediaItem
                implicitWidth: mediaRow.implicitWidth + 16
                Layout.fillHeight: true

                RowLayout {
                    id: mediaRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰎆"
                        color: root.hasMedia ? Colours.blue : Colours.overlay0
                        font.family: Colours.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Black
                    }

                    Text {
                        text: {
                            if (!root.hasMedia)
                                return "No media";
                            var t = root.state_.mediaTitle;
                            return t.length > 30 ? t.substring(0, 30) + "…" : t;
                        }
                        color: root.hasMedia ? Colours.text : Colours.overlay0
                        font.family: Colours.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Black
                    }
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) {
                            var mapped = mediaItem.mapToGlobal(mediaItem.width / 2, 0);
                            root.state_.mediaAudioX = mapped.x;
                            root.state_.mediaAudioOpen = true;
                        } else {
                            mediaAudioHideTimer.restart();
                        }
                    }
                }
            }
        }

        // ── Center ──────────────────────────────────────────────────────────
        RowLayout {
            anchors.centerIn: parent
            spacing: 0

            Repeater {
                model: 10
                delegate: WorkspaceButton {
                    required property int index
                    wsId: index + 1
                }
            }
        }

        // ── Right ────────────────────────────────────────────────────────────
        RowLayout {
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                rightMargin: 4
            }
            spacing: 0

            Item {
                id: submapItem
                implicitWidth: submapRow.implicitWidth + 16
                Layout.fillHeight: true
                visible: root.activeSubmap !== ""

                RowLayout {
                    id: submapRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰩨"
                        color: Colours.red
                        font.family: Colours.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Black
                    }

                    Text {
                        text: root.activeSubmap
                        color: Colours.red
                        font.family: Colours.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Black
                    }
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }
            }

            Item {
                id: notifItem
                implicitWidth: notifRow.implicitWidth + 16
                Layout.fillHeight: true
                visible: root.notifCount > 0

                RowLayout {
                    id: notifRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰂚"
                        color: Colours.mauve
                        font.family: Colours.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Black
                    }

                    Text {
                        text: root.notifCount.toString()
                        color: Colours.mauve
                        font.family: Colours.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Black
                    }
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.state_.clearNotifs()
                }
            }

            Text {
                text: "󰍛 " + root.cpuUsage + "%"
                color: Colours.peach
                font.family: Colours.fontFamily
                font.pixelSize: 18
                font.weight: Font.Black
                leftPadding: 8
                rightPadding: 8
            }

            Item {
                implicitWidth: memLabel.implicitWidth + 16
                Layout.fillHeight: true

                Text {
                    id: memLabel
                    anchors.centerIn: parent
                    text: "󰾆 " + root.memUsage + "%"
                    color: Colours.blue
                    font.family: Colours.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Black
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }
            }

            Text {
                text: root.netType === "wifi" ? "󰤨" : root.netType === "ethernet" ? "󰈀" : "󰤭"
                color: root.netType === "" ? Colours.overlay0 : Colours.sky
                font.family: Colours.fontFamily
                font.pixelSize: 18
                font.weight: Font.Black
                leftPadding: 8
                rightPadding: 8
                MouseArea {
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                }
            }

            // ── Power button ─────────────────────────────────────────────────
            Item {
                id: powerItem
                implicitWidth: powerLabel.implicitWidth + 20
                Layout.fillHeight: true

                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                }

                Text {
                    id: powerLabel
                    anchors.centerIn: parent
                    text: "⏻"
                    font.family: Colours.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: root.state_.powerOpen ? Colours.red : Qt.rgba(Colours.overlay1.r, Colours.overlay1.g, Colours.overlay1.b, 0.8)
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                MouseArea {
                    id: powerArea
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
