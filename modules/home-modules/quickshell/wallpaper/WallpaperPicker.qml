import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    width: 820
    height: 620
    radius: 14
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.97)
    border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.45)
    border.width: 1

    MouseArea {
        anchors.fill: parent
    }

    property var wallpapers: []
    property string searchText: ""
    property var filtered: {
        var term = searchText.toLowerCase();
        if (term === "")
            return wallpapers;
        return wallpapers.filter(function (w) {
            return w.name.toLowerCase().indexOf(term) !== -1;
        });
    }

    readonly property int cols: 4
    readonly property real gridWidth: root.width - 32
    readonly property real cellW: Math.floor(gridWidth / cols)
    readonly property real cellH: 158

    Component.onCompleted: {
        searchInput.forceActiveFocus();
        loadProc.running = true;
    }

    Process {
        id: loadProc
        command: ["qs-wallpapers"]
        stdout: SplitParser {
            onRead: function (line) {
                try {
                    root.wallpapers = root.wallpapers.concat([JSON.parse(line)]);
                } catch (_) {}
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: " Wallpaper"
                color: Colours.lavender
                font.family: Colours.fontFamily
                font.pixelSize: 18
                font.weight: Font.Light
            }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                color: Colours.text
                font.family: Colours.fontFamily
                font.pixelSize: 18
                font.weight: Font.Light
                onTextChanged: root.searchText = text
                Keys.onEscapePressed: Qt.quit()

                Text {
                    anchors.fill: parent
                    text: "filter wallpapers…"
                    color: Colours.overlay0
                    font: parent.font
                    visible: parent.text === ""
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)
        }

        GridView {
            id: wallGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cellWidth: root.cellW
            cellHeight: root.cellH
            cacheBuffer: root.cellH * 2
            model: root.filtered

            delegate: Item {
                width: wallGrid.cellWidth
                height: wallGrid.cellHeight

                Rectangle {
                    id: tile
                    anchors {
                        fill: parent
                        margins: 5
                    }
                    radius: 10
                    color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.5)
                    border.color: mouseArea.containsMouse ? Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.6) : Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.3)
                    border.width: 1
                    clip: true
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    Image {
                        id: thumbImage
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: parent.height - 22
                        source: modelData.path
                        fillMode: Image.PreserveAspectCrop
                        smooth: false
                        asynchronous: true
                        sourceSize.width: root.cellW - 10
                        sourceSize.height: root.cellH - 32
                    }

                    Rectangle {
                        anchors.fill: thumbImage
                        color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.3)
                        visible: thumbImage.status !== Image.Ready
                        radius: parent.radius
                    }

                    Rectangle {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
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
                            color: mouseArea.containsMouse ? Colours.lavender : Colours.subtext0
                            font.family: Colours.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.rgba(Colours.lavender.r, Colours.lavender.g, Colours.lavender.b, 0.10)
                        opacity: mouseArea.containsMouse ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 80
                            }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var path = modelData.path.replace("file://", "");
                            Quickshell.execDetached(["qs-setwall", path]);
                            Qt.quit();
                        }
                    }
                }
            }
        }
    }
}
