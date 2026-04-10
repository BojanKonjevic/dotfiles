import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: root

    width: Colours.popupClipText
    height: Colours.popupClipTextH
    radius: Colours.radiusPopup
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, Colours.opacityPanel)
    border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacityBorder)
    border.width: 1

    MouseArea {
        anchors.fill: parent
    }

    property string searchText: ""
    property var entries: []
    property int currentIndex: 0

    property var filteredEntries: {
        var term = searchText.toLowerCase();
        if (term === "")
            return entries;
        return entries.filter(function (e) {
            return e.content.toLowerCase().indexOf(term) !== -1;
        });
    }

    onFilteredEntriesChanged: currentIndex = 0

    onCurrentIndexChanged: {
        var item = clipRepeater.itemAt(currentIndex);
        if (!item)
            return;
        var itemY = item.y;
        var itemH = item.height;
        if (itemY < clipFlick.contentY)
            clipFlick.contentY = itemY;
        else if (itemY + itemH > clipFlick.contentY + clipFlick.height)
            clipFlick.contentY = itemY + itemH - clipFlick.height;
    }

    Component.onCompleted: {
        searchInput.forceActiveFocus();
        listProc.running = true;
    }

    function reload() {
        root.entries = [];
        listProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
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
        id: copyProc
        property string entryLine: ""
        command: ["qs-clip-copy-text", entryLine]
        onExited: Qt.quit()
    }

    Process {
        id: clearProc
        command: ["qs-clip-clear-text"]
        onExited: root.reload()
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Colours.spacingLg
        }
        spacing: Colours.iconSizeSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Colours.spacingXs + Colours.spacingXs + 2

            Text {
                text: "  Text"
                color: Colours.sapphire
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeLg
                font.weight: Font.Light
            }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                color: Colours.text
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeLg
                font.weight: Font.Light
                onTextChanged: root.searchText = text

                Keys.onEscapePressed: Qt.quit()

                Keys.onReturnPressed: {
                    var entry = root.filteredEntries[root.currentIndex];
                    if (entry) {
                        copyProc.entryLine = entry.id + "\t" + entry.content;
                        copyProc.running = true;
                    }
                }

                Keys.onDownPressed: {
                    if (root.filteredEntries.length === 0)
                        return;
                    root.currentIndex = (root.currentIndex + 1) % root.filteredEntries.length;
                }

                Keys.onUpPressed: {
                    if (root.filteredEntries.length === 0)
                        return;
                    root.currentIndex = (root.currentIndex - 1 + root.filteredEntries.length) % root.filteredEntries.length;
                }

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
                font.pixelSize: Colours.iconSizeLg + Colours.spacingSm
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

        Flickable {
            id: clipFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: clipColumn.height

            Column {
                id: clipColumn
                width: parent.width
                spacing: Colours.spacingXs

                Repeater {
                    id: clipRepeater
                    model: root.filteredEntries
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: clipColumn.width
                        height: Colours.spacingXl + Colours.spacingSm
                        radius: Colours.radiusRow
                        color: (index === root.currentIndex || rowHover.containsMouse) ? Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.18) : "transparent"
                        border.color: (index === root.currentIndex || rowHover.containsMouse) ? Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.55) : "transparent"
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
                                leftMargin: Colours.spacingMd
                                rightMargin: Colours.spacingMd
                            }
                            text: modelData.content
                            color: (index === root.currentIndex || rowHover.containsMouse) ? Colours.sapphire : Colours.subtext0
                            font.family: Colours.fontFamily
                            font.pixelSize: Colours.fontSizeMd
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
                                root.currentIndex = index;
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
