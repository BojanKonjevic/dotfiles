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
    implicitWidth: Colours.barWidth
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.90)

    property bool hasMedia: root.state_.mediaStatus !== "Stopped" && root.state_.mediaTitle !== ""

    property string clockHour: Qt.formatDateTime(new Date(), "hh")
    property string clockMin: Qt.formatDateTime(new Date(), "mm")
    property string activeSubmap: root.state_.activeSubmap
    property int notifCount: root.state_.notifCount

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.clockHour = Qt.formatDateTime(new Date(), "hh");
            root.clockMin = Qt.formatDateTime(new Date(), "mm");
        }
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
                implicitHeight: clockCol.implicitHeight + Colours.spacingXl

                ColumnLayout {
                    id: clockCol
                    anchors.centerIn: parent
                    spacing: -Colours.spacingXs

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.clockHour
                        color: Colours.mauve
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeXl
                        font.weight: Font.Black
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.clockMin
                        color: Colours.blue
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeXl
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
                        leftMargin: Colours.spacingMd
                        rightMargin: Colours.spacingMd
                    }
                    height: 1
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.25)
                }
            }

            // ── Workspaces ───────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: wsCol.implicitHeight + Colours.iconSizeSm

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
                Layout.leftMargin: Colours.spacingMd
                Layout.rightMargin: Colours.spacingMd
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.25)
            }

            // ── CPU bar ──────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: Colours.spacingXl + Colours.spacingSm

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Colours.spacingSm

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰍛"
                        color: Qt.rgba(Colours.peach.r, Colours.peach.g, Colours.peach.b, 0.4 + root.state_.cpuUsage / 100 * 0.6)
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.iconSizeSm
                        font.weight: Font.Black
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: Colours.barWidth - Colours.spacingXl
                        height: Colours.sliderTrackH
                        radius: 1
                        color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)

                        Rectangle {
                            width: parent.width * (root.state_.cpuUsage / 100)
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
                implicitHeight: Colours.spacingXl + Colours.spacingSm

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Colours.spacingSm

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰾆"
                        color: Qt.rgba(Colours.blue.r, Colours.blue.g, Colours.blue.b, 0.4 + root.state_.memUsage / 100 * 0.6)
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.iconSizeSm
                        font.weight: Font.Black
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: Colours.barWidth - Colours.spacingXl
                        height: Colours.sliderTrackH
                        radius: 1
                        color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)

                        Rectangle {
                            width: parent.width * (root.state_.memUsage / 100)
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
                implicitHeight: Colours.spacingXl + Colours.spacingSm
                visible: root.activeSubmap !== ""

                Text {
                    anchors.centerIn: parent
                    text: "󰩨"
                    color: Colours.red
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeMd
                    font.weight: Font.Black
                }
            }

            // ── Media ────────────────────────────────────────────────────────
            Item {
                id: mediaItem
                Layout.fillWidth: true
                implicitHeight: Colours.spacingXl + Colours.spacingSm

                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    color: root.hasMedia ? Colours.blue : Qt.rgba(Colours.overlay0.r, Colours.overlay0.g, Colours.overlay0.b, 0.5)
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeMd
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
                Layout.leftMargin: Colours.spacingMd
                Layout.rightMargin: Colours.spacingMd
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.25)
            }

            // ── Notifications ─────────────────────────────────────────────────
            Item {
                id: notifItem
                Layout.fillWidth: true
                implicitHeight: Colours.spacingXl + Colours.spacingSm
                visible: root.notifCount > 0

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    color: root.state_.notifPanelOpen ? Colours.mauve : Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.6)
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeMd
                    font.weight: Font.Black
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        horizontalCenterOffset: Colours.spacingXs + Colours.spacingXs
                        topMargin: Colours.spacingXs + Colours.spacingXs
                    }
                    width: Colours.spacingXs + 2
                    height: Colours.spacingXs + 2
                    radius: Colours.spacingXs
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
                implicitHeight: Colours.spacingXl + Colours.spacingSm

                Text {
                    anchors.centerIn: parent
                    text: root.state_.micMuted ? "󰍭" : "󰍬"
                    color: root.state_.micMuted ? Colours.red : Colours.green
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeMd
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
                implicitHeight: Colours.spacingXl + Colours.spacingSm

                Text {
                    anchors.centerIn: parent
                    text: root.state_.netType === "wifi" ? "󰤨" : root.state_.netType === "ethernet" ? "󰈀" : "󰤭"
                    color: root.state_.netType === "" ? Qt.rgba(Colours.overlay0.r, Colours.overlay0.g, Colours.overlay0.b, 0.5) : Colours.sky
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeMd
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
                implicitHeight: Colours.spacingXl + Colours.spacingSm + 4
                Layout.bottomMargin: 4

                Text {
                    anchors.centerIn: parent
                    text: "⏻"
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeMd
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
