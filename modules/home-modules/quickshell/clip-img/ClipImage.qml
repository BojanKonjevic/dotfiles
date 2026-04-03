import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: root

    width: 820
    height: 600
    radius: 14
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.97)
    border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.45)
    border.width: 1

    MouseArea {
        anchors.fill: parent
    }

    property var images: []

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
            color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: imgGrid.height

            Flow {
                id: imgGrid
                width: parent.width
                spacing: 10

                Repeater {
                    model: root.images
                    delegate: Rectangle {
                        required property var modelData
                        width: 178
                        height: 130
                        radius: 10
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
                            smooth: true
                            // Cap texture size — loading full-res images as thumbs kills memory
                            sourceSize.width: 200
                            sourceSize.height: 150
                            asynchronous: true
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
}
