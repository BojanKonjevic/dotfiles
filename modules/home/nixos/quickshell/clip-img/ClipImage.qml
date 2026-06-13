import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: root

    width: Colours.popupClipImg
    height: Colours.popupClipImgH
    radius: Colours.radiusPopup
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.82)
    border.color: Qt.rgba(Colours.green.r, Colours.green.g, Colours.green.b, 0.18)
    border.width: 1

    // Top edge highlight
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 1
        radius: root.radius
        color: Qt.rgba(Colours.green.r, Colours.green.g, Colours.green.b, 0.25)
    }

    MouseArea {
        anchors.fill: parent
    }

    // ListModel — natively watched by Repeater, no JS array tricks
    ListModel {
        id: imgModel
    }

    readonly property int cols: 4
    readonly property real pad: Colours.spacingLg
    readonly property real gap: Colours.spacingMd
    readonly property real cellW: Math.floor((root.width - pad * 2 - gap * (cols - 1)) / cols)
    readonly property real cellH: cellW // square thumbnails

    function reload() {
        imgModel.clear();
        loadProc.running = false;
        loadProc.running = true;
    }

    Component.onCompleted: loadProc.running = true

    Process {
        id: loadProc
        command: ["qs-clip-images"]
        stdout: SplitParser {
            onRead: function (line) {
                try {
                    var item = JSON.parse(line);
                    imgModel.append({
                        entryId: item.id,
                        content: item.content,
                        path: item.path
                    });
                } catch (_) {}
            }
        }
    }

    Process {
        id: copyProc
        property string entryLine: ""
        command: ["qs-clip-copy-img", entryLine]
        onExited: Qt.quit()
    }

    Process {
        id: clearProc
        command: ["qs-clip-clear-img"]
        onExited: root.reload()
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
                    color: Qt.rgba(Colours.green.r, Colours.green.g, Colours.green.b, 0.12)
                    border.color: Qt.rgba(Colours.green.r, Colours.green.g, Colours.green.b, 0.3)
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "󰋩"
                        color: Colours.green
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.iconSizeMd
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Images"
                    color: Colours.text
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.fontSizeLg
                    font.weight: Font.Light
                }

                // Count badge
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: imgModel.count > 0
                    width: Math.max(badgeText.implicitWidth + Colours.spacingSm * 2, Colours.spacingXl)
                    height: Colours.fontSizeSm + Colours.spacingXs * 2
                    radius: height / 2
                    color: Qt.rgba(Colours.green.r, Colours.green.g, Colours.green.b, 0.15)
                    border.color: Qt.rgba(Colours.green.r, Colours.green.g, Colours.green.b, 0.3)
                    border.width: 1
                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: imgModel.count.toString()
                        color: Colours.green
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeXs
                        font.weight: Font.Bold
                    }
                }
            }

            // Clear all button
            Rectangle {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                visible: imgModel.count > 0
                width: clearRow.implicitWidth + Colours.spacingMd * 2
                height: Colours.spacingXl
                radius: Colours.radiusRow
                color: clearHover.containsMouse ? Qt.rgba(Colours.red.r, Colours.red.g, Colours.red.b, 0.15) : Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.5)
                border.color: clearHover.containsMouse ? Qt.rgba(Colours.red.r, Colours.red.g, Colours.red.b, 0.4) : Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.4)
                border.width: 1
                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
                Behavior on border.color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                Row {
                    id: clearRow
                    anchors.centerIn: parent
                    spacing: Colours.spacingXs

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰆴"
                        color: clearHover.containsMouse ? Colours.red : Colours.overlay1
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeSm
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Clear all"
                        color: clearHover.containsMouse ? Colours.red : Colours.overlay1
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeSm
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }
                }

                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: clearProc.running = true
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

        // Empty state
        Column {
            anchors.centerIn: parent
            anchors.topMargin: header.height + divider.height
            spacing: Colours.spacingSm
            visible: imgModel.count === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰋩"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSize2Xl
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No images in clipboard"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeSm
            }
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
            visible: imgModel.count > 0
            clip: true
            contentWidth: width
            contentHeight: {
                var rows = Math.ceil(imgModel.count / root.cols);
                return rows > 0 ? rows * root.cellH + (rows - 1) * root.gap : 0;
            }
            boundsBehavior: Flickable.StopAtBounds

            Item {
                width: parent.width
                height: parent.contentHeight

                Repeater {
                    model: imgModel

                    delegate: Item {
                        id: tile
                        required property string entryId
                        required property string content
                        required property string path
                        required property int index

                        readonly property int col: index % root.cols
                        readonly property int row: Math.floor(index / root.cols)

                        x: col * (root.cellW + root.gap)
                        y: row * (root.cellH + root.gap)
                        width: root.cellW
                        height: root.cellH

                        property bool hovered: false

                        transform: Scale {
                            origin.x: root.cellW / 2
                            origin.y: root.cellH / 2
                            xScale: tile.hovered ? 1.04 : 1.0
                            yScale: tile.hovered ? 1.04 : 1.0
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
                            border.color: Qt.rgba(Colours.green.r, Colours.green.g, Colours.green.b, tile.hovered ? 0.5 : 0.0)
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
                            color: Qt.rgba(Colours.mantle.r, Colours.mantle.g, Colours.mantle.b, 0.65)
                            border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, tile.hovered ? 0.5 : 0.25)
                            border.width: 1
                            clip: true
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            // Thumbnail
                            Image {
                                id: thumb
                                anchors.fill: parent
                                source: tile.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: root.cellW * 2
                                sourceSize.height: root.cellH * 2
                                smooth: true
                                cache: true
                                opacity: status === Image.Ready ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }

                            // Placeholder while loading
                            Rectangle {
                                anchors.fill: parent
                                visible: thumb.status !== Image.Ready
                                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.3)
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰋩"
                                    color: Qt.rgba(Colours.overlay0.r, Colours.overlay0.g, Colours.overlay0.b, 0.35)
                                    font.family: Colours.fontFamily
                                    font.pixelSize: Colours.fontSizeLg
                                }
                            }

                            // Hover overlay with copy icon
                            Rectangle {
                                anchors.fill: parent
                                radius: Colours.radiusTile
                                color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.55)
                                opacity: tile.hovered ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆏"
                                    color: Colours.green
                                    font.family: Colours.fontFamily
                                    font.pixelSize: Colours.fontSize2Xl
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
                                copyProc.entryLine = tile.entryId + "\t" + tile.content;
                                copyProc.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
