import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: root

    width: 820
    implicitHeight: Math.min(620, header.implicitHeight + grid.implicitHeight + 48)
    radius: 14
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.97)
    border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.45)
    border.width: 1

    MouseArea {
        anchors.fill: parent
    }

    property var wallpapers: []

    Process {
        id: loadProc
        command: ["qs-wallpapers"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                try {
                    root.wallpapers = root.wallpapers.concat([JSON.parse(line)]);
                } catch (_) {}
            }
        }
    }

    Process {
        id: setProc
        property string path: ""
        command: path !== "" ? ["qs-setwall", path] : []
        onRunningChanged: if (!running && path !== "")
            Qt.quit()
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 14

        RowLayout {
            id: header
            Layout.fillWidth: true

            Text {
                text: "  Wallpaper"
                color: Colours.lavender
                font.family: Colours.fontFamily
                font.pixelSize: 18
                font.weight: Font.Light
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
            contentHeight: grid.implicitHeight

            Flow {
                id: grid
                width: parent.width
                spacing: 10

                Repeater {
                    model: root.wallpapers
                    delegate: Rectangle {
                        required property var modelData
                        width: 178
                        height: 148
                        radius: 10
                        color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.5)
                        border.color: tileHover.containsMouse ? Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.6) : Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.3)
                        border.width: 1
                        clip: true
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 80
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Image {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                source: modelData.path
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 22
                                color: Qt.rgba(Colours.mantle.r, Colours.mantle.g, Colours.mantle.b, 0.9)

                                Text {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 6
                                        rightMargin: 6
                                    }
                                    text: modelData.name
                                    color: tileHover.containsMouse ? Colours.lavender : Colours.subtext0
                                    font.family: Colours.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 80
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.10)
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
                                // Strip file:// prefix for swww
                                var path = modelData.path.replace("file://", "");
                                setProc.path = path;
                                setProc.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
