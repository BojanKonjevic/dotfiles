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
    margins.left: Colours.barWidth
    margins.top: Math.max(4, Math.min(state_.mediaAudioY - Colours.spacingXl, screen.height - implicitHeight - 4))
    implicitWidth: state_.mediaAudioOpen ? Colours.panelMediaAudio + Colours.iconSizeLg : 0
    implicitHeight: state_.mediaAudioOpen ? content.height + 2 : 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    HoverHandler {
        onHoveredChanged: {
            root.state_.mediaAudioPanelHovered = hovered;
        }
    }

    // ── Volume debounce ───────────────────────────────────────────────────────
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

    // ── Cava ──────────────────────────────────────────────────────────────────
    property var cavaBars: []

    Process {
        id: cavaProc
        command: ["qs-cava-bar"]
        running: root.state_.mediaAudioOpen && root.state_.mediaTitle !== ""
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
        width: Colours.panelMediaAudio
        height: root.state_.mediaAudioOpen ? innerCol.implicitHeight + Colours.spacingXl : 0
        radius: Colours.radiusPanel
        color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, Colours.opacityPanel)
        border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacityBorder)
        border.width: 1
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        opacity: root.state_.mediaAudioOpen ? 1.0 : 0.0
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
                margins: Colours.iconSizeSm
            }
            spacing: 0

            // ── MEDIA ─────────────────────────────────────────────────────────

            Item {
                Layout.fillWidth: true
                implicitHeight: Colours.spacingXl + Colours.spacingMd
                visible: root.state_.mediaTitle === ""
                Layout.topMargin: 4
                Layout.bottomMargin: 4

                Text {
                    anchors.centerIn: parent
                    text: "No media playing"
                    color: Colours.overlay0
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.fontSizeMd
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Colours.spacingMd
                visible: root.state_.mediaTitle !== ""
                Layout.topMargin: 4
                Layout.bottomMargin: Colours.spacingMd

                Rectangle {
                    width: Colours.mediaArtSize
                    height: Colours.mediaArtSize
                    radius: Colours.radiusRow
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
                        font.pixelSize: Colours.fontSize2Xl
                        visible: root.state_.mediaArtUrl === ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Colours.spacingXs
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: root.state_.mediaTitle
                        color: Colours.text
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeMd
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.state_.mediaArtist
                        color: Colours.subtext0
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeSm
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        visible: text !== ""
                    }

                    Text {
                        text: root.state_.mediaAlbum
                        color: Colours.overlay1
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeSm
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.state_.mediaTitle !== ""
                Layout.bottomMargin: Colours.spacingMd

                Rectangle {
                    id: progressBar
                    Layout.fillWidth: true
                    height: Colours.progressH
                    radius: Colours.radiusSmall
                    color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.6)

                    property bool dragging: false
                    property real dragPosition: root.state_.mediaPosition

                    Rectangle {
                        width: root.state_.mediaLength > 0 ? parent.width * ((progressBar.dragging ? progressBar.dragPosition : root.state_.mediaPosition) / root.state_.mediaLength) : 0
                        height: parent.height
                        radius: parent.radius
                        color: Colours.blue
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: progressBar.dragging = true
                        onReleased: function (mouse) {
                            progressBar.dragging = false;
                            var secs = (mouse.x / progressBar.width) * root.state_.mediaLength;
                            Quickshell.execDetached(["playerctl", "position", secs.toFixed(1)]);
                        }
                        onPositionChanged: function (mouse) {
                            if (progressBar.dragging) {
                                progressBar.dragPosition = Math.max(0, Math.min(mouse.x / progressBar.width, 1.0)) * root.state_.mediaLength;
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.formatTime(root.state_.mediaPosition)
                        color: Colours.overlay0
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeXs
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.formatTime(root.state_.mediaLength)
                        color: Colours.overlay0
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeXs
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.state_.mediaTitle !== ""
                Layout.bottomMargin: Colours.spacingMd

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    id: prevBtn
                    text: "󰒮"
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeLg
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
                    width: Colours.spacingXl + Colours.spacingMd + 4
                    height: Colours.spacingXl + Colours.spacingMd + 4
                    radius: (Colours.spacingXl + Colours.spacingMd + 4) / 2
                    color: Qt.rgba(Colours.blue.r, Colours.blue.g, Colours.blue.b, 0.15)
                    border.color: Qt.rgba(Colours.blue.r, Colours.blue.g, Colours.blue.b, 0.3)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.state_.mediaStatus === "Playing" ? "󰏤" : "󰐊"
                        color: Colours.blue
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.iconSizeLg
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
                    font.pixelSize: Colours.iconSizeLg
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
                implicitHeight: Colours.spacingXl + Colours.spacingMd
                visible: root.state_.mediaTitle !== ""
                Layout.bottomMargin: Colours.spacingMd

                Row {
                    anchors.fill: parent
                    spacing: 2

                    Repeater {
                        model: Colours.cavaBars
                        delegate: Item {
                            width: (parent.width - (Colours.cavaBars - 1) * 2) / Colours.cavaBars
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

            // ── Divider ───────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                Layout.bottomMargin: Colours.spacingMd
            }

            // ── MIC / INPUT ───────────────────────────────────────────────────
            Text {
                text: "MIC"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeXs
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.bottomMargin: Colours.spacingXs + Colours.spacingXs + 2
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Colours.spacingSm
                spacing: Colours.spacingXs + Colours.spacingXs + 2

                Text {
                    text: root.state_.audioData && root.state_.audioData.input.muted ? "󰍭" : "󰍬"
                    color: root.state_.audioData && root.state_.audioData.input.muted ? Colours.red : Colours.green
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeMd
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
                    }
                }

                Item {
                    id: inSlider
                    Layout.fillWidth: true
                    implicitHeight: Colours.iconSizeLg
                    property real dragValue: root.state_.audioData ? Math.min(root.state_.audioData.input.volume, 1.5) : 0
                    property bool dragging: false

                    Connections {
                        target: root.state_
                        function onAudioDataChanged() {
                            if (!inSlider.dragging && root.state_.audioData)
                                inSlider.dragValue = Math.min(root.state_.audioData.input.volume, 1.5);
                        }
                    }

                    Rectangle {
                        id: inTrack
                        anchors.verticalCenter: inSlider.verticalCenter
                        width: inSlider.width
                        height: Colours.sliderTrackH
                        radius: Colours.radiusSmall
                        color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.6)

                        Rectangle {
                            width: Math.min(inSlider.width * (inSlider.dragValue / 1.5), inTrack.width)
                            height: parent.height
                            radius: parent.radius
                            color: root.state_.audioData && root.state_.audioData.input.muted ? Colours.red : Colours.green
                        }
                    }

                    Rectangle {
                        x: Math.min(inSlider.width * (inSlider.dragValue / 1.5), inSlider.width) - width / 2
                        anchors.verticalCenter: inSlider.verticalCenter
                        width: Colours.sliderThumb
                        height: Colours.sliderThumb
                        radius: Colours.sliderThumb / 2
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
                    font.pixelSize: Colours.fontSizeSm
                    Layout.minimumWidth: Colours.spacingXl + Colours.spacingMd
                    horizontalAlignment: Text.AlignRight
                }
            }

            Text {
                text: root.state_.audioData ? root.state_.audioData.input.desc : ""
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeXs
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.bottomMargin: Colours.spacingMd
            }

            // ── Divider ───────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                Layout.bottomMargin: Colours.spacingMd
            }

            // ── OUTPUT ────────────────────────────────────────────────────────
            Text {
                text: "OUTPUT"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeXs
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.topMargin: 4
                Layout.bottomMargin: Colours.spacingXs + Colours.spacingXs + 2
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Colours.spacingSm
                spacing: Colours.spacingXs + Colours.spacingXs + 2

                Text {
                    text: root.state_.audioData && root.state_.audioData.output.muted ? "󰖁" : "󰕾"
                    color: Colours.blue
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeMd
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                    }
                }

                Item {
                    id: outSlider
                    Layout.fillWidth: true
                    implicitHeight: Colours.iconSizeLg
                    property real dragValue: root.state_.audioData ? Math.min(root.state_.audioData.output.volume, 1.5) : 0
                    property bool dragging: false

                    Connections {
                        target: root.state_
                        function onAudioDataChanged() {
                            if (!outSlider.dragging && root.state_.audioData)
                                outSlider.dragValue = Math.min(root.state_.audioData.output.volume, 1.5);
                        }
                    }

                    Rectangle {
                        id: outTrack
                        anchors.verticalCenter: outSlider.verticalCenter
                        width: outSlider.width
                        height: Colours.sliderTrackH
                        radius: Colours.radiusSmall
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
                        width: Colours.sliderThumb
                        height: Colours.sliderThumb
                        radius: Colours.sliderThumb / 2
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
                    font.pixelSize: Colours.fontSizeSm
                    Layout.minimumWidth: Colours.spacingXl + Colours.spacingMd
                    horizontalAlignment: Text.AlignRight
                }
            }

            Text {
                text: root.state_.audioData ? root.state_.audioData.output.desc : ""
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeXs
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.bottomMargin: Colours.spacingMd
            }

            // ── APPS ──────────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                Layout.bottomMargin: Colours.spacingMd
                visible: root.state_.audioData && root.state_.audioData.apps.length > 0
            }

            Text {
                text: "APPS"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeXs
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.bottomMargin: Colours.spacingXs + Colours.spacingXs + 2
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
                        font.pixelSize: Colours.fontSizeSm
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Colours.spacingXs + Colours.spacingXs + 2

                        Item {
                            id: appSlider
                            Layout.fillWidth: true
                            implicitHeight: Colours.iconSizeLg
                            property real dragValue: Math.min(appDelegate.modelData.volume, 1.5)
                            property bool dragging: false
                            property int appIndex: appDelegate.modelData.index

                            Connections {
                                target: appDelegate
                                function onModelDataChanged() {
                                    if (!appSlider.dragging)
                                        appSlider.dragValue = Math.min(appDelegate.modelData.volume, 1.5);
                                }
                            }

                            Rectangle {
                                id: appTrack
                                anchors.verticalCenter: appSlider.verticalCenter
                                width: appSlider.width
                                height: Colours.sliderTrackH
                                radius: Colours.radiusSmall
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
                                width: Colours.sliderThumb
                                height: Colours.sliderThumb
                                radius: Colours.sliderThumb / 2
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
                            font.pixelSize: Colours.fontSizeSm
                            Layout.minimumWidth: Colours.spacingXl + Colours.spacingMd
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
