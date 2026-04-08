import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: root

    width: 820
    height: 600
    radius: Colours.radiusPopup
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, Colours.opacityPanel)
    border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacityBorder)
    border.width: 1

    MouseArea {
        anchors.fill: parent
    }

    property var images: []

    readonly property int cols: 4
    readonly property real gridWidth: root.width - 32
    readonly property real cellW: Math.floor(gridWidth / cols)
    readonly property real cellH: 148

    function reload() {
        root.images = [];
        loadProc.running = true;
    }

    Component.onCompleted: loadProc.running = true

    Process {
        id: loadProc
        command: ["qs-clip-images"]
        stdout: SplitParser {
            onRead: function (line) {
                try {
                    root.images = root.images.concat([JSON.parse(line)]);
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

    ColumnLayout {
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 14

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "  Images"
                color: Colours.green
                font.family: Colours.fontFamily
                font.pixelSize: 18
                font.weight: Font.Light
                Layout.fillWidth: true
            }

            Text {
                text: "󰆴"
                color: Qt.rgba(Colours.red.r, Colours.red.g, Colours.red.b, 0.5)
                font.family: Colours.fontFamily
                font.pixelSize: 22
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: clearProc.running = true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
        }

        GridView {
            id: imgGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cellWidth: root.cellW
            cellHeight: root.cellH
            cacheBuffer: root.cellH * 2
            model: root.images

            delegate: Item {
                width: imgGrid.cellWidth
                height: imgGrid.cellHeight

                Rectangle {
                    anchors {
                        fill: parent
                        margins: 5
                    }
                    radius: Colours.radiusTile
                    color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.5)
                    border.color: tileHover.containsMouse ? Qt.rgba(Colours.green.r, Colours.green.g, Colours.green.b, 0.6) : Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.3)
                    border.width: 1
                    clip: true
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    Image {
                        anchors {
                            fill: parent
                            margins: 4
                        }
                        source: modelData.path
                        fillMode: Image.PreserveAspectCrop
                        smooth: false
                        asynchronous: true
                        sourceSize.width: root.cellW - 10
                        sourceSize.height: root.cellH - 10
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.rgba(Colours.green.r, Colours.green.g, Colours.green.b, 0.12)
                        opacity: tileHover.containsMouse ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 80
                            }
                        }
                    }

                    MouseArea {
                        id: tileHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            copyProc.entryLine = modelData.id + "\t" + modelData.content;
                            copyProc.running = true;
                        }
                    }
                }
            }
        }
    }
}
