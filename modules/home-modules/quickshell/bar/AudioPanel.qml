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
    margins.left: Math.max(4, Math.min(state_.audioX - 150, screen.width - 308))

    implicitWidth: state_.audioOpen ? 300 : 0
    implicitHeight: state_.audioOpen ? 300 : 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    HoverHandler {
        onHoveredChanged: {
            root.state_.audioPanelHovered = hovered;
        }
    }

    property string pendingType: ""
    property string pendingArg1: ""
    property string pendingArg2: ""

    Timer {
        id: setDebounce
        interval: 80
        onTriggered: {
            if (root.pendingType === "")
                return;
            if (root.pendingType === "app") {
                Quickshell.execDetached(["qs-audio-set", "app", root.pendingArg1, root.pendingArg2]);
            } else {
                Quickshell.execDetached(["qs-audio-set", root.pendingType, root.pendingArg1]);
            }
            root.pendingType = "";
        }
    }

    function setVolume(type, arg1, arg2) {
        root.pendingType = type;
        root.pendingArg1 = arg1;
        root.pendingArg2 = arg2 || "";
        setDebounce.restart();
    }

    Rectangle {
        id: content
        anchors {
            top: parent.top
            left: parent.left
        }
        width: 280
        height: root.state_.audioOpen ? innerCol.implicitHeight + 24 : 0
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

        opacity: root.state_.audioOpen ? 1.0 : 0.0
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
                margins: 14
            }
            spacing: 0

            // ── Output ────────────────────────────────────────────────────────
            Text {
                text: "OUTPUT"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.topMargin: 4
                Layout.bottomMargin: 8
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                spacing: 8

                Text {
                    text: root.state_.audioData && root.state_.audioData.output.muted ? "󰖁" : "󰕾"
                    color: Colours.blue
                    font.family: Colours.fontFamily
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                    }
                }

                Item {
                    id: outSlider
                    Layout.fillWidth: true
                    implicitHeight: 20

                    // dragValue is the live display value updated on mouse move
                    // it is synced from audioData when not being dragged
                    property real dragValue: root.state_.audioData ? Math.min(root.state_.audioData.output.volume, 1.5) : 0
                    property bool dragging: false

                    // sync from external data only when not dragging
                    Connections {
                        target: root.state_
                        function onAudioDataChanged() {
                            if (!outSlider.dragging && root.state_.audioData) {
                                outSlider.dragValue = Math.min(root.state_.audioData.output.volume, 1.5);
                            }
                        }
                    }

                    Rectangle {
                        id: outTrack
                        anchors.verticalCenter: outSlider.verticalCenter
                        width: outSlider.width
                        height: 3
                        radius: 2
                        color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.6)

                        Rectangle {
                            width: Math.min(outSlider.width * (outSlider.dragValue / 1.5), outTrack.width)
                            height: parent.height
                            radius: parent.radius
                            color: outSlider.dragValue > 1.0 ? Colours.peach : Colours.blue
                        }
                    }

                    Rectangle {
                        x: Math.min(outSlider.width * (outSlider.dragValue / 1.5), outSlider.width) - width / 2
                        anchors.verticalCenter: outSlider.verticalCenter
                        width: 12
                        height: 12
                        radius: 6
                        color: Colours.text
                    }

                    MouseArea {
                        anchors.fill: outSlider
                        cursorShape: Qt.PointingHandCursor
                        onPressed: outSlider.dragging = true
                        onReleased: outSlider.dragging = false
                        onPositionChanged: function (mouse) {
                            var v = Math.max(0, Math.min(mouse.x / outSlider.width, 1.0)) * 1.5;
                            outSlider.dragValue = v;
                            root.setVolume("sink", v.toFixed(2));
                        }
                        onClicked: function (mouse) {
                            var v = Math.max(0, Math.min(mouse.x / outSlider.width, 1.0)) * 1.5;
                            outSlider.dragValue = v;
                            root.setVolume("sink", v.toFixed(2));
                        }
                    }
                }

                Text {
                    text: Math.round(outSlider.dragValue * 100) + "%"
                    color: Colours.subtext0
                    font.family: Colours.fontFamily
                    font.pixelSize: 11
                    Layout.minimumWidth: 32
                    horizontalAlignment: Text.AlignRight
                }
            }

            Text {
                text: root.state_.audioData ? root.state_.audioData.output.desc : ""
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.bottomMargin: 12
            }

            // ── Divider ──────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.4)
                Layout.bottomMargin: 12
            }

            // ── Input ─────────────────────────────────────────────────────────
            Text {
                text: "INPUT"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.bottomMargin: 8
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                spacing: 8

                Text {
                    text: root.state_.audioData && root.state_.audioData.input.muted ? "󰍭" : "󰍬"
                    color: root.state_.audioData && root.state_.audioData.input.muted ? Colours.red : Colours.green
                    font.family: Colours.fontFamily
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
                    }
                }

                Item {
                    id: inSlider
                    Layout.fillWidth: true
                    implicitHeight: 20

                    property real dragValue: root.state_.audioData ? Math.min(root.state_.audioData.input.volume, 1.5) : 0
                    property bool dragging: false

                    Connections {
                        target: root.state_
                        function onAudioDataChanged() {
                            if (!inSlider.dragging && root.state_.audioData) {
                                inSlider.dragValue = Math.min(root.state_.audioData.input.volume, 1.5);
                            }
                        }
                    }

                    Rectangle {
                        id: inTrack
                        anchors.verticalCenter: inSlider.verticalCenter
                        width: inSlider.width
                        height: 3
                        radius: 2
                        color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.6)

                        Rectangle {
                            width: Math.min(inSlider.width * (inSlider.dragValue / 1.5), inTrack.width)
                            height: parent.height
                            radius: parent.radius
                            color: Colours.green
                        }
                    }

                    Rectangle {
                        x: Math.min(inSlider.width * (inSlider.dragValue / 1.5), inSlider.width) - width / 2
                        anchors.verticalCenter: inSlider.verticalCenter
                        width: 12
                        height: 12
                        radius: 6
                        color: Colours.text
                    }

                    MouseArea {
                        anchors.fill: inSlider
                        cursorShape: Qt.PointingHandCursor
                        onPressed: inSlider.dragging = true
                        onReleased: inSlider.dragging = false
                        onPositionChanged: function (mouse) {
                            var v = Math.max(0, Math.min(mouse.x / inSlider.width, 1.0)) * 1.5;
                            inSlider.dragValue = v;
                            root.setVolume("source", v.toFixed(2));
                        }
                        onClicked: function (mouse) {
                            var v = Math.max(0, Math.min(mouse.x / inSlider.width, 1.0)) * 1.5;
                            inSlider.dragValue = v;
                            root.setVolume("source", v.toFixed(2));
                        }
                    }
                }

                Text {
                    text: Math.round(inSlider.dragValue * 100) + "%"
                    color: Colours.subtext0
                    font.family: Colours.fontFamily
                    font.pixelSize: 11
                    Layout.minimumWidth: 32
                    horizontalAlignment: Text.AlignRight
                }
            }

            Text {
                text: root.state_.audioData ? root.state_.audioData.input.desc : ""
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.bottomMargin: 12
            }

            // ── Apps ──────────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.4)
                Layout.bottomMargin: 12
                visible: root.state_.audioData && root.state_.audioData.apps.length > 0
            }

            Text {
                text: "APPS"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.bottomMargin: 8
                visible: root.state_.audioData && root.state_.audioData.apps.length > 0
            }

            Repeater {
                model: root.state_.audioData ? root.state_.audioData.apps : []
                delegate: ColumnLayout {
                    id: appDelegate
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 4
                    Layout.bottomMargin: 10

                    Text {
                        text: appDelegate.modelData.name
                        color: Colours.subtext0
                        font.family: Colours.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Item {
                            id: appSlider
                            Layout.fillWidth: true
                            implicitHeight: 20
                            property real dragValue: Math.min(appDelegate.modelData.volume, 1.5)
                            property bool dragging: false
                            property int appIndex: appDelegate.modelData.index

                            // sync from model when not dragging
                            Connections {
                                target: appDelegate
                                function onModelDataChanged() {
                                    if (!appSlider.dragging) {
                                        appSlider.dragValue = Math.min(appDelegate.modelData.volume, 1.5);
                                    }
                                }
                            }

                            Rectangle {
                                id: appTrack
                                anchors.verticalCenter: appSlider.verticalCenter
                                width: appSlider.width
                                height: 3
                                radius: 2
                                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.6)

                                Rectangle {
                                    width: Math.min(appSlider.width * (appSlider.dragValue / 1.5), appTrack.width)
                                    height: parent.height
                                    radius: parent.radius
                                    color: Colours.mauve
                                }
                            }

                            Rectangle {
                                x: Math.min(appSlider.width * (appSlider.dragValue / 1.5), appSlider.width) - width / 2
                                anchors.verticalCenter: appSlider.verticalCenter
                                width: 12
                                height: 12
                                radius: 6
                                color: Colours.text
                            }

                            MouseArea {
                                anchors.fill: appSlider
                                cursorShape: Qt.PointingHandCursor
                                onPressed: appSlider.dragging = true
                                onReleased: appSlider.dragging = false
                                onPositionChanged: function (mouse) {
                                    var v = Math.max(0, Math.min(mouse.x / appSlider.width, 1.0)) * 150;
                                    appSlider.dragValue = v / 100.0;
                                    root.setVolume("app", appSlider.appIndex.toString(), Math.round(v).toString());
                                }
                                onClicked: function (mouse) {
                                    var v = Math.max(0, Math.min(mouse.x / appSlider.width, 1.0)) * 150;
                                    appSlider.dragValue = v / 100.0;
                                    root.setVolume("app", appSlider.appIndex.toString(), Math.round(v).toString());
                                }
                            }
                        }

                        Text {
                            text: Math.round(appSlider.dragValue * 100) + "%"
                            color: Colours.subtext0
                            font.family: Colours.fontFamily
                            font.pixelSize: 11
                            Layout.minimumWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            Item {
                implicitHeight: 2
            }
        }
    }
}
