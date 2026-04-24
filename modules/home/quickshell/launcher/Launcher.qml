import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    width: Colours.popupLauncher
    height: Colours.popupLauncherH
    radius: Colours.radiusPopup
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.82)
    border.color: Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.18)
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
        color: Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.25)
    }

    MouseArea {
        anchors.fill: parent
    }

    property string searchText: ""
    property int currentIndex: 0

    readonly property real pad: Colours.spacingLg

    Component.onCompleted: searchInput.forceActiveFocus()

    function launch(app) {
        app.execute();
        Qt.quit();
    }

    // ── UI ───────────────────────────────────────────────────────────────────
    Item {
        anchors {
            fill: parent
            margins: root.pad
        }

        // ── Search bar ───────────────────────────────────────────────────────
        Rectangle {
            id: searchBar
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: Colours.spacingXl + Colours.spacingMd
            radius: Colours.radiusRow
            color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.6)
            border.color: searchInput.activeFocus ? Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.6) : Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.4)
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
                spacing: Colours.spacingMd

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    color: searchInput.activeFocus ? Colours.mauve : Colours.overlay1
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.fontSizeLg
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                TextInput {
                    id: searchInput
                    width: parent.width - Colours.iconSizeXl - Colours.spacingMd
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colours.text
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.fontSizeLg
                    font.weight: Font.Light

                    onTextChanged: {
                        root.searchText = text.toLowerCase();
                        var first = root.nextVisible(0, root.searchText);
                        root.currentIndex = first >= 0 ? first : 0;
                        appList.positionViewAtBeginning();
                    }

                    Keys.onEscapePressed: Qt.quit()

                    Keys.onReturnPressed: {
                        var item = appList.itemAtIndex(root.currentIndex);
                        if (item && item.visible)
                            root.launch(item.app);
                    }

                    Keys.onDownPressed: {
                        var next = root.nextVisible(root.currentIndex + 1, root.searchText);
                        if (next >= 0) {
                            root.currentIndex = next;
                            appList.positionViewAtIndex(next, ListView.Contain);
                        }
                    }

                    Keys.onUpPressed: {
                        var prev = root.prevVisible(root.currentIndex - 1, root.searchText);
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
        }

        // Divider
        Rectangle {
            id: divider
            anchors {
                top: searchBar.bottom
                left: parent.left
                right: parent.right
                topMargin: Colours.spacingMd
            }
            height: 1
            color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.3)
        }

        // ── App list ─────────────────────────────────────────────────────────
        ListView {
            id: appList
            anchors {
                top: divider.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: Colours.spacingMd
            }
            clip: true
            model: DesktopEntries.applications
            currentIndex: root.currentIndex
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 600
            spacing: 0

            delegate: Item {
                id: row
                required property var modelData
                required property int index

                readonly property var app: modelData
                readonly property bool matches: {
                    var t = root.searchText;
                    if (t === "")
                        return true;
                    if (modelData.name.toLowerCase().indexOf(t) !== -1)
                        return true;
                    if (modelData.comment && modelData.comment.toLowerCase().indexOf(t) !== -1)
                        return true;
                    return false;
                }
                readonly property bool isSelected: index === root.currentIndex

                visible: matches
                width: appList.width
                height: matches ? Colours.spacingXl + Colours.spacingLg + Colours.spacingXs + 2 : 0

                // Hover state
                property bool hovered: false

                // Background
                Rectangle {
                    anchors.fill: parent
                    radius: Colours.radiusRow
                    color: row.isSelected ? Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.15) : row.hovered ? Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.6) : "transparent"
                    border.color: row.isSelected ? Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.4) : "transparent"
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    // Left accent bar when selected
                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: 2
                        radius: 1
                        color: Colours.mauve
                        opacity: row.isSelected ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 80
                            }
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
                        spacing: Colours.spacingMd

                        // App icon
                        Item {
                            width: Colours.iconSizeXl
                            height: Colours.iconSizeXl
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.fill: parent
                                source: row.modelData.icon !== "" ? "image://icon/" + row.modelData.icon : ""
                                visible: row.modelData.icon !== "" && status === Image.Ready
                                sourceSize.width: Colours.iconSizeXl
                                sourceSize.height: Colours.iconSizeXl
                                smooth: true
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                            }

                            // Fallback icon when missing
                            Text {
                                anchors.centerIn: parent
                                text: "󰀻"
                                color: row.isSelected ? Colours.mauve : Colours.overlay1
                                font.family: Colours.fontFamily
                                font.pixelSize: Colours.iconSizeXl
                                visible: row.modelData.icon === "" || row.modelData.icon === undefined
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }
                            }
                        }

                        // Name + comment
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - Colours.iconSizeXl - Colours.spacingMd
                            spacing: 2

                            Text {
                                width: parent.width
                                text: row.modelData.name
                                color: row.isSelected ? Colours.mauve : Colours.text
                                font.family: Colours.fontFamily
                                font.pixelSize: Colours.fontSizeMd
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: row.modelData.comment || ""
                                color: row.isSelected ? Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.6) : Colours.overlay1
                                font.family: Colours.fontFamily
                                font.pixelSize: Colours.fontSizeXs
                                elide: Text.ElideRight
                                visible: text !== ""
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
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
                    onEntered: {
                        row.hovered = true;
                        root.currentIndex = row.index;
                    }
                    onExited: row.hovered = false
                    onClicked: root.launch(row.modelData)
                }
            }
        }
    }

    // ── Keyboard navigation helpers ───────────────────────────────────────────
    function nextVisible(from, term) {
        if (term === undefined)
            term = root.searchText;
        for (var i = from; i < appList.count; i++) {
            var item = appList.itemAtIndex(i);
            if (!item)
                continue;
            var n = item.modelData.name.toLowerCase();
            var c = (item.modelData.comment || "").toLowerCase();
            if (term === "" || n.indexOf(term) !== -1 || c.indexOf(term) !== -1)
                return i;
        }
        for (var j = 0; j < from; j++) {
            var item2 = appList.itemAtIndex(j);
            if (!item2)
                continue;
            var n2 = item2.modelData.name.toLowerCase();
            var c2 = (item2.modelData.comment || "").toLowerCase();
            if (term === "" || n2.indexOf(term) !== -1 || c2.indexOf(term) !== -1)
                return j;
        }
        return -1;
    }

    function prevVisible(from, term) {
        if (term === undefined)
            term = root.searchText;
        for (var i = from; i >= 0; i--) {
            var item = appList.itemAtIndex(i);
            if (!item)
                continue;
            var n = item.modelData.name.toLowerCase();
            var c = (item.modelData.comment || "").toLowerCase();
            if (term === "" || n.indexOf(term) !== -1 || c.indexOf(term) !== -1)
                return i;
        }
        for (var j = appList.count - 1; j > from; j--) {
            var item2 = appList.itemAtIndex(j);
            if (!item2)
                continue;
            var n2 = item2.modelData.name.toLowerCase();
            var c2 = (item2.modelData.comment || "").toLowerCase();
            if (term === "" || n2.indexOf(term) !== -1 || c2.indexOf(term) !== -1)
                return j;
        }
        return -1;
    }
}
