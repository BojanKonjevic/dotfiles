import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root
    required property var state_

    anchors {
        top: true
        left: true
    }
    margins.top: 28
    margins.left: {
        var s = screen ? screen.width : 1920;
        return Math.floor(s * 0.35);
    }

    implicitWidth: 340
    implicitHeight: state_.mediaOpen ? 340 : 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    HoverHandler {
        onHoveredChanged: {
            root.state_.mediaPanelHovered = hovered;
            if (!hovered)
                root.state_.mediaOpen = false;
        }
    }

    property var cavaBars: []

    Process {
        id: cavaProc
        command: ["qs-cava-bar"]
        running: root.state_.mediaOpen
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                var parts = data.trim().split(";").filter(function (x) {
                    return x !== "";
                });
                if (parts.length > 0) {
                    root.cavaBars = parts.map(function (x) {
                        return parseInt(x) || 0;
                    });
                }
            }
        }
    }

    function formatTime(secs) {
        if (isNaN(secs) || secs < 0)
            return "0:00";
        var s = Math.floor(secs);
        var m = Math.floor(s / 60);
        s = s % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    Rectangle {
        id: content
        anchors {
            top: parent.top
            left: parent.left
        }
        width: 320
        height: root.state_.mediaOpen ? innerCol.implicitHeight + 24 : 0
        radius: 12
        color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.97)
        border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.45)
        border.width: 1
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        opacity: root.state_.mediaOpen ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }

        ColumnLayout {
            id: innerCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            spacing: 0

            // ── No media state ────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 60
                visible: root.state_.mediaTitle === ""

                Text {
                    anchors.centerIn: parent
                    text: "No media playing"
                    color: Colours.overlay0
                    font.family: Colours.fontFamily
                    font.pixelSize: 13
                }
            }

            // ── Art + metadata ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                visible: root.state_.mediaTitle !== ""
                Layout.topMargin: 4
                Layout.bottomMargin: 12

                Rectangle {
                    width: 64
                    height: 64
                    radius: 8
                    color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.8)
                    clip: true
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.fill: parent
                        source: root.state_.mediaArtUrl
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰎆"
                        color: Colours.overlay1
                        font.family: Colours.fontFamily
                        font.pixelSize: 28
                        visible: root.state_.mediaArtUrl === ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: root.state_.mediaTitle
                        color: Colours.text
                        font.family: Colours.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.state_.mediaArtist
                        color: Colours.subtext0
                        font.family: Colours.fontFamily
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        visible: text !== ""
                    }

                    Text {
                        text: root.state_.mediaAlbum
                        color: Colours.overlay1
                        font.family: Colours.fontFamily
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }

            // ── Progress bar ──────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.state_.mediaTitle !== ""
                Layout.bottomMargin: 12

                Rectangle {
                    Layout.fillWidth: true
                    height: 3
                    radius: 2
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.6)

                    Rectangle {
                        width: root.state_.mediaLength > 0 ? parent.width * (root.state_.mediaPosition / root.state_.mediaLength) : 0
                        height: parent.height
                        radius: parent.radius
                        color: Colours.blue
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.formatTime(root.state_.mediaPosition)
                        color: Colours.overlay0
                        font.family: Colours.fontFamily
                        font.pixelSize: 10
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.formatTime(root.state_.mediaLength)
                        color: Colours.overlay0
                        font.family: Colours.fontFamily
                        font.pixelSize: 10
                    }
                }
            }

            // ── Controls ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                visible: root.state_.mediaTitle !== ""
                Layout.bottomMargin: 12

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    id: prevBtn
                    text: "󰒮"
                    font.family: Colours.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.Black
                    property bool hovered_: false
                    color: hovered_ ? Colours.text : Colours.overlay1
                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    HoverHandler {
                        onHoveredChanged: prevBtn.hovered_ = hovered
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["playerctl", "previous"])
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: Qt.rgba(Colours.blue.r, Colours.blue.g, Colours.blue.b, 0.15)
                    border.color: Qt.rgba(Colours.blue.r, Colours.blue.g, Colours.blue.b, 0.3)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.state_.mediaStatus === "Playing" ? "󰏤" : "󰐊"
                        color: Colours.blue
                        font.family: Colours.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Black
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["playerctl", "play-pause"])
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    id: nextBtn
                    text: "󰒭"
                    font.family: Colours.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.Black
                    property bool hovered_: false
                    color: hovered_ ? Colours.text : Colours.overlay1
                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    HoverHandler {
                        onHoveredChanged: nextBtn.hovered_ = hovered
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["playerctl", "next"])
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            // ── Cava visualizer ───────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 32
                visible: root.state_.mediaTitle !== ""
                Layout.bottomMargin: 4

                Row {
                    anchors.fill: parent
                    spacing: 2

                    Repeater {
                        model: 20
                        delegate: Item {
                            width: (parent.width - 19 * 2) / 20
                            height: parent.height

                            Rectangle {
                                width: parent.width
                                height: Math.max(2, (root.cavaBars[index] || 0) / 15.0 * parent.height)
                                anchors.bottom: parent.bottom
                                radius: 1
                                color: Qt.rgba(Colours.blue.r, Colours.blue.g, Colours.blue.b, 0.4 + (root.cavaBars[index] || 0) / 15.0 * 0.6)
                            }
                        }
                    }
                }
            }
        }
    }
}
