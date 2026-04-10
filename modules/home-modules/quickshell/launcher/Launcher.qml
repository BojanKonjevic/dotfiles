import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    width: Colours.popupLauncher
    height: Colours.popupLauncherH
    radius: Colours.radiusPopup
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, Colours.opacityPanel)
    border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacityBorder)
    border.width: 1

    MouseArea {
        anchors.fill: parent
    }

    property string searchText: ""
    property int currentIndex: -1

    onSearchTextChanged: {
        root.currentIndex = -1;
        resetTimer.restart();
    }

    Timer {
        id: resetTimer
        interval: 16
        onTriggered: {
            for (var i = 0; i < appList.count; i++) {
                var item = appList.itemAtIndex(i);
                if (item && item.visible) {
                    root.currentIndex = i;
                    appList.positionViewAtIndex(i, ListView.Beginning);
                    return;
                }
            }
            root.currentIndex = -1;
        }
    }

    Component.onCompleted: searchInput.forceActiveFocus()

    function launch(app) {
        app.execute();
        Qt.quit();
    }

    function nextVisible(from) {
        for (var i = from; i < appList.count; i++) {
            var item = appList.itemAtIndex(i);
            if (item && item.visible)
                return i;
        }
        for (var j = 0; j < from; j++) {
            var item2 = appList.itemAtIndex(j);
            if (item2 && item2.visible)
                return j;
        }
        return -1;
    }

    function prevVisible(from) {
        for (var i = from; i >= 0; i--) {
            var item = appList.itemAtIndex(i);
            if (item && item.visible)
                return i;
        }
        for (var j = appList.count - 1; j > from; j--) {
            var item2 = appList.itemAtIndex(j);
            if (item2 && item2.visible)
                return j;
        }
        return -1;
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Colours.spacingLg
        }
        spacing: Colours.iconSizeSm

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Colours.spacingXs + Colours.spacingXs + 2

                Text {
                    text: " "
                    color: Colours.mauve
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

                    onTextChanged: root.searchText = text.toLowerCase()

                    Keys.onEscapePressed: Qt.quit()

                    Keys.onReturnPressed: {
                        var idx = root.currentIndex;
                        if (idx < 0)
                            return;
                        var item = appList.itemAtIndex(idx);
                        if (item && item.visible)
                            root.launch(item.app);
                    }

                    Keys.onDownPressed: {
                        var next = root.nextVisible(root.currentIndex + 1);
                        if (next >= 0) {
                            root.currentIndex = next;
                            appList.positionViewAtIndex(next, ListView.Contain);
                        }
                    }

                    Keys.onUpPressed: {
                        var prev = root.prevVisible(root.currentIndex - 1);
                        if (prev >= 0) {
                            root.currentIndex = prev;
                            appList.positionViewAtIndex(prev, ListView.Contain);
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
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                Layout.topMargin: 10
            }
        }

        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: DesktopEntries.applications
            currentIndex: root.currentIndex
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 200

            delegate: AppEntry {
                required property var modelData
                required property int index
                app: modelData
                width: appList.width
                selected: index === root.currentIndex
                visible: root.searchText === "" || modelData.name.toLowerCase().indexOf(root.searchText) !== -1 || (modelData.comment && modelData.comment.toLowerCase().indexOf(root.searchText) !== -1)
                height: visible ? implicitHeight : 0
                onClicked: root.launch(modelData)
            }
        }
    }
}
