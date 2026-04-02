import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: root

    width: 640
    height: 480
    radius: 14
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.97)
    border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.45)
    border.width: 1

    MouseArea {
        anchors.fill: parent
    }

    property string searchText: ""
    property var entries: []

    property var filteredEntries: {
        var term = searchText.toLowerCase();
        if (term === "")
            return entries;
        return entries.filter(function (e) {
            return e.content.toLowerCase().indexOf(term) !== -1;
        });
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                var tab = line.indexOf('\t');
                if (tab === -1)
                    return;
                var id = line.substring(0, tab);
                var content = line.substring(tab + 1);
                if (content.indexOf("[[ binary data") !== -1)
                    return;
                root.entries = root.entries.concat([
                    {
                        id: id,
                        content: content
                    }
                ]);
            }
        }
    }

    Process {
        id: decodeProc
        property string entryLine: ""
        command: ["cliphist", "decode"]
        onStarted: {
            stdin.write(entryLine);
            stdin.close();
        }
        stdout: SplitParser {
            onRead: function (data) {
                copyProc.textToCopy = data;
            }
        }
        onExited: if (copyProc.textToCopy !== "")
            copyProc.running = true
    }

    Process {
        id: copyProc
        property string textToCopy: ""
        command: ["wl-copy"]
        onStarted: {
            stdin.write(textToCopy);
            stdin.close();
        }
        onExited: Qt.quit()
    }

    Process {
        id: clearProc
        command: ["qs-clip-clear-text"]
        onExited: Qt.quit()
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
                text: "  Text"
                color: Colours.sapphire
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
                focus: true
                onTextChanged: root.searchText = text

                Text {
                    anchors.fill: parent
                    text: "search clipboard…"
                    color: Colours.overlay0
                    font: parent.font
                    visible: parent.text === ""
                }
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
            contentHeight: clipColumn.height

            Column {
                id: clipColumn
                width: parent.width
                spacing: 3

                Repeater {
                    model: root.filteredEntries
                    delegate: Rectangle {
                        required property var modelData
                        width: clipColumn.width
                        height: 36
                        radius: 8
                        color: rowHover.containsMouse ? Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.18) : "transparent"
                        border.color: rowHover.containsMouse ? Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.55) : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: 60
                            }
                        }

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 12
                                rightMargin: 12
                            }
                            text: modelData.content
                            color: rowHover.containsMouse ? Colours.sapphire : Colours.subtext0
                            font.family: Colours.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Behavior on color {
                                ColorAnimation {
                                    duration: 60
                                }
                            }
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                decodeProc.entryLine = modelData.id + "\t" + modelData.content;
                                decodeProc.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
