import QtQuick
import QtQuick.Layouts
import Quickshell.Services.DesktopEntries

Rectangle {
    id: root

    width: 580
    height: 520
    radius: 14
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.97)
    border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.45)
    border.width: 1

    MouseArea {
        anchors.fill: parent
    }

    property string searchText: ""

    Component.onCompleted: searchInput.forceActiveFocus()

    ColumnLayout {
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: " "
                    color: Colours.mauve
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
                    onTextChanged: root.searchText = text.toLowerCase()

                    Keys.onReturnPressed: {
                        for (var i = 0; i < appRepeater.count; i++) {
                            var item = appRepeater.itemAt(i);
                            if (item && item.visible) {
                                item.app.execute();
                                Qt.quit();
                                return;
                            }
                        }
                    }

                    Text {
                        anchors.fill: parent
                        text: "Search applications…"
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
                Layout.topMargin: 10
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: appColumn.height

            Column {
                id: appColumn
                width: parent.width
                spacing: 2

                Repeater {
                    id: appRepeater
                    model: DesktopEntries.applications
                    delegate: AppEntry {
                        required property var modelData
                        app: modelData
                        width: appColumn.width
                        visible: root.searchText === "" || modelData.name.toLowerCase().indexOf(root.searchText) !== -1 || (modelData.comment && modelData.comment.toLowerCase().indexOf(root.searchText) !== -1)
                    }
                }
            }
        }
    }
}
