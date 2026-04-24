import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    width: Colours.popupWallpaper
    height: Colours.popupWallpaperH
    radius: Colours.radiusPopup
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.82)
    border.color: Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.18)
    border.width: 1

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 1
        radius: root.radius
        color: Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.25)
    }

    MouseArea {
        anchors.fill: parent
    }

    property string searchText: ""
    property string currentWall: ""

    // ListModel — Repeater watches this natively, no JS array tricks needed
    ListModel {
        id: wallModel
    }

    readonly property int cols: 3
    readonly property real pad: Colours.spacingLg
    readonly property real gap: Colours.spacingMd
    readonly property real cellW: Math.floor((root.width - pad * 2 - gap * (cols - 1)) / cols)
    readonly property real thumbH: Math.floor(cellW * 9 / 16)
    readonly property real nameBarH: Colours.fontSizeSm + Colours.spacingMd
    readonly property real cellH: thumbH + nameBarH

    Component.onCompleted: {
        searchInput.forceActiveFocus();
        currentWallProc.running = true;
        loadProc.running = true;
    }

    Process {
        id: currentWallProc
        command: ["bash", "-c", "f=$(readlink -f \"$HOME/Pictures/wallpapers/wall.jpg\" 2>/dev/null); [ -f \"$f\" ] && basename \"$f\""]
        stdout: SplitParser {
            onRead: function (line) {
                var n = line.trim();
                if (n !== "")
                    root.currentWall = n;
            }
        }
    }

    Process {
        id: loadProc
        command: ["qs-wallpapers"]
        stdout: SplitParser {
            onRead: function (line) {
                try {
                    var item = JSON.parse(line);
                    wallModel.append({
                        name: item.name,
                        path: item.path
                    });
                } catch (_) {}
            }
        }
    }

    // ── UI ───────────────────────────────────────────────────────────────────
    Item {
        anchors {
            fill: parent
            margins: root.pad
        }

        // ── Header ───────────────────────────────────────────────────────────
        Item {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: Colours.spacingXl

            Row {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                spacing: Colours.spacingSm

                Rectangle {
                    width: Colours.iconSizeLg + Colours.spacingSm
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.12)
                    border.color: Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.3)
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "󰸉"
                        color: Colours.lavender
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.iconSizeMd
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wallpaper"
                    color: Colours.text
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.fontSizeLg
                    font.weight: Font.Light
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: wallModel.count > 0
                    width: Math.max(badgeText.implicitWidth + Colours.spacingSm * 2, Colours.spacingXl)
                    height: Colours.fontSizeSm + Colours.spacingXs * 2
                    radius: height / 2
                    color: Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.15)
                    border.color: Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.3)
                    border.width: 1
                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: wallModel.count.toString()
                        color: Colours.lavender
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeXs
                        font.weight: Font.Bold
                    }
                }
            }

            // Search pill
            Rectangle {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                width: 180
                height: Colours.spacingXl
                radius: Colours.spacingXl / 2
                color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.7)
                border.color: searchInput.activeFocus ? Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.55) : Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)
                border.width: 1
                Behavior on border.color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: Colours.spacingMd
                        rightMargin: Colours.spacingMd
                    }
                    spacing: Colours.spacingSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        color: searchInput.activeFocus ? Colours.lavender : Colours.overlay1
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeSm
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }

                    TextInput {
                        id: searchInput
                        width: 130
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colours.text
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeSm
                        onTextChanged: root.searchText = text
                        Keys.onEscapePressed: Qt.quit()

                        Text {
                            anchors.fill: parent
                            text: "filter…"
                            color: Colours.overlay0
                            font: parent.font
                            visible: parent.text === ""
                        }
                    }
                }
            }
        }

        // Divider
        Rectangle {
            id: divider
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                topMargin: Colours.spacingMd
            }
            height: 1
            color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.3)
        }

        // ── Grid ─────────────────────────────────────────────────────────────
        Flickable {
            anchors {
                top: divider.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: Colours.spacingMd
            }
            clip: true
            contentWidth: width
            // Height is driven by visible rows — delegates with height:0 when filtered
            contentHeight: {
                var visCount = 0;
                for (var i = 0; i < wallModel.count; i++) {
                    var n = wallModel.get(i).name;
                    if (root.searchText === "" || n.toLowerCase().indexOf(root.searchText.toLowerCase()) !== -1)
                        visCount++;
                }
                var rows = Math.ceil(visCount / root.cols);
                return rows > 0 ? rows * root.cellH + (rows - 1) * root.gap : 0;
            }
            boundsBehavior: Flickable.StopAtBounds

            // Manual positioned grid — delegates hide themselves when filtered out
            // We track visible index separately for positioning
            Item {
                id: gridContent
                width: parent.width
                height: parent.contentHeight

                Repeater {
                    model: wallModel

                    delegate: Item {
                        id: tile
                        required property string name
                        required property string path
                        required property int index

                        readonly property bool matches: root.searchText === "" || name.toLowerCase().indexOf(root.searchText.toLowerCase()) !== -1
                        readonly property bool isCurrent: name === root.currentWall

                        // Compute position among only visible items
                        readonly property int visIndex: {
                            var v = 0;
                            for (var i = 0; i < tile.index; i++) {
                                var n = wallModel.get(i).name;
                                if (root.searchText === "" || n.toLowerCase().indexOf(root.searchText.toLowerCase()) !== -1)
                                    v++;
                            }
                            return v;
                        }
                        readonly property int col: visIndex % root.cols
                        readonly property int row: Math.floor(visIndex / root.cols)

                        visible: matches
                        width: root.cellW
                        height: root.cellH
                        x: col * (root.cellW + root.gap)
                        y: row * (root.cellH + root.gap)

                        property bool hovered: false

                        transform: Scale {
                            origin.x: root.cellW / 2
                            origin.y: root.cellH / 2
                            xScale: tile.hovered ? 1.03 : 1.0
                            yScale: tile.hovered ? 1.03 : 1.0
                            Behavior on xScale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on yScale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // Outer glow ring
                        Rectangle {
                            anchors {
                                fill: parent
                                margins: -2
                            }
                            radius: Colours.radiusTile + 2
                            color: "transparent"
                            border.width: 2
                            border.color: tile.isCurrent ? Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, tile.hovered ? 0.9 : 0.6) : Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, tile.hovered ? 0.45 : 0.0)
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }

                        // Card
                        Rectangle {
                            anchors.fill: parent
                            radius: Colours.radiusTile
                            color: tile.hovered ? Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.8) : Qt.rgba(Colours.mantle.r, Colours.mantle.g, Colours.mantle.b, 0.65)
                            border.color: tile.isCurrent ? Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.7) : Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, tile.hovered ? 0.5 : 0.25)
                            border.width: tile.isCurrent ? 2 : 1
                            clip: true
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Image {
                                id: thumb
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                }
                                height: root.thumbH
                                source: tile.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: root.cellW * 2
                                sourceSize.height: root.thumbH * 2
                                smooth: true
                                cache: true
                                opacity: status === Image.Ready ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }

                            // Placeholder
                            Rectangle {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                }
                                height: root.thumbH
                                visible: thumb.status !== Image.Ready
                                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.35)
                            }

                            // Gradient
                            Rectangle {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                }
                                height: root.thumbH
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop {
                                        position: 0.55
                                        color: "transparent"
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: Qt.rgba(0, 0, 0, 0.5)
                                    }
                                }
                                opacity: tile.hovered ? 1.0 : 0.4
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            // Active checkmark
                            Rectangle {
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    margins: Colours.spacingSm
                                }
                                width: Colours.iconSizeMd + 4
                                height: width
                                radius: width / 2
                                color: Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.9)
                                visible: tile.isCurrent
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰸞"
                                    color: Colours.crust
                                    font.family: Colours.fontFamily
                                    font.pixelSize: Colours.fontSizeXs
                                    font.weight: Font.Black
                                }
                            }

                            // Name bar
                            Rectangle {
                                anchors {
                                    bottom: parent.bottom
                                    left: parent.left
                                    right: parent.right
                                }
                                height: root.nameBarH
                                color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, tile.hovered ? 0.9 : 0.75)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Row {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: Colours.spacingSm
                                        rightMargin: Colours.spacingSm
                                    }
                                    spacing: Colours.spacingXs

                                    Text {
                                        width: parent.width - (arrow.width + Colours.spacingXs)
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: tile.name
                                        color: tile.hovered ? Colours.lavender : Colours.subtext0
                                        font.family: Colours.fontFamily
                                        font.pixelSize: Colours.fontSizeXs
                                        elide: Text.ElideRight
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }
                                    }

                                    Text {
                                        id: arrow
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰁔"
                                        color: Colours.lavender
                                        font.family: Colours.fontFamily
                                        font.pixelSize: Colours.fontSizeXs
                                        opacity: tile.hovered ? 1.0 : 0.0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 120
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: tile.hovered = true
                            onExited: tile.hovered = false
                            onClicked: {
                                var p = tile.path.replace("file://", "");
                                if (p === "")
                                    return;
                                root.currentWall = tile.name;
                                Quickshell.execDetached(["qs-setwall", p]);
                                Qt.quit();
                            }
                        }
                    }
                }
            }
        }
    }
}
