import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: root

    width: Colours.popupClipText
    height: Colours.popupClipTextH
    radius: Colours.radiusPopup
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.82)
    border.color: Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.18)
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
        color: Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.25)
    }

    MouseArea {
        anchors.fill: parent
    }

    property string searchText: ""
    property int currentIndex: 0

    // ListModel — natively watched, no JS array tricks
    ListModel {
        id: clipModel
    }

    function reload() {
        clipModel.clear();
        listProc.running = false;
        listProc.running = true;
        searchInput.text = "";
        root.currentIndex = 0;
    }

    Component.onCompleted: {
        searchInput.forceActiveFocus();
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
                clipModel.append({
                    entryId: id,
                    content: content
                });
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

    // Keyboard navigation — operates on visible items only
    function nextVisible(from) {
        var term = root.searchText;
        for (var i = from; i < clipModel.count; i++) {
            if (term === "" || clipModel.get(i).content.toLowerCase().indexOf(term) !== -1)
                return i;
        }
        return -1;
    }

    function prevVisible(from) {
        var term = root.searchText;
        for (var i = from; i >= 0; i--) {
            if (term === "" || clipModel.get(i).content.toLowerCase().indexOf(term) !== -1)
                return i;
        }
        return -1;
    }

    function commitCurrent() {
        var item = clipList.itemAtIndex(root.currentIndex);
        if (item && item.matches) {
            copyProc.entryLine = item.entryId + "\t" + item.content;
            copyProc.running = true;
        }
    }

    readonly property real pad: Colours.spacingLg

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
                    color: Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.12)
                    border.color: Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.3)
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "󰅍"
                        color: Colours.sapphire
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.iconSizeMd
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clipboard"
                    color: Colours.text
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.fontSizeLg
                    font.weight: Font.Light
                }

                // Count badge
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: clipModel.count > 0
                    width: Math.max(badgeText.implicitWidth + Colours.spacingSm * 2, Colours.spacingXl)
                    height: Colours.fontSizeSm + Colours.spacingXs * 2
                    radius: height / 2
                    color: Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.15)
                    border.color: Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.3)
                    border.width: 1
                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: clipModel.count.toString()
                        color: Colours.sapphire
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
                visible: clipModel.count > 0
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

        // ── Search bar ───────────────────────────────────────────────────────
        Rectangle {
            id: searchBar
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                topMargin: Colours.spacingMd
            }
            height: Colours.spacingXl
            radius: Colours.radiusRow
            color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.6)
            border.color: searchInput.activeFocus ? Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.6) : Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.4)
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
                    color: searchInput.activeFocus ? Colours.sapphire : Colours.overlay1
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.fontSizeMd
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                TextInput {
                    id: searchInput
                    width: parent.width - Colours.iconSizeLg - Colours.spacingMd
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colours.text
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.fontSizeMd
                    font.weight: Font.Light

                    onTextChanged: {
                        root.searchText = text.toLowerCase();
                        var first = root.nextVisible(0);
                        root.currentIndex = first >= 0 ? first : 0;
                        clipList.positionViewAtBeginning();
                    }

                    Keys.onEscapePressed: Qt.quit()
                    Keys.onReturnPressed: root.commitCurrent()

                    Keys.onDownPressed: {
                        var next = root.nextVisible(root.currentIndex + 1);
                        if (next >= 0) {
                            root.currentIndex = next;
                            clipList.positionViewAtIndex(next, ListView.Contain);
                        }
                    }

                    Keys.onUpPressed: {
                        var prev = root.prevVisible(root.currentIndex - 1);
                        if (prev >= 0) {
                            root.currentIndex = prev;
                            clipList.positionViewAtIndex(prev, ListView.Contain);
                        }
                    }

                    Text {
                        anchors.fill: parent
                        text: "search clipboard…"
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

        // Empty state
        Column {
            anchors.centerIn: parent
            spacing: Colours.spacingSm
            visible: clipModel.count === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰅍"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSize2Xl
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Clipboard is empty"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeSm
            }
        }

        // ── Entry list ───────────────────────────────────────────────────────
        ListView {
            id: clipList
            anchors {
                top: divider.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: Colours.spacingMd
            }
            visible: clipModel.count > 0
            clip: true
            model: clipModel
            currentIndex: root.currentIndex
            boundsBehavior: Flickable.StopAtBounds
            // Virtualization — only renders visible rows, keeps large lists fast
            cacheBuffer: 200
            spacing: 0

            delegate: Item {
                id: row
                required property string entryId
                required property string content
                required property int index

                readonly property bool matches: root.searchText === "" || content.toLowerCase().indexOf(root.searchText) !== -1
                readonly property bool isSelected: index === root.currentIndex

                visible: matches
                width: clipList.width
                height: matches ? Colours.spacingXl + Colours.spacingXs + 2 : 0

                property bool hovered: false

                // Background
                Rectangle {
                    anchors {
                        fill: parent
                        bottomMargin: 2
                    }
                    radius: Colours.radiusRow
                    color: row.isSelected ? Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.15) : row.hovered ? Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.6) : "transparent"
                    border.color: row.isSelected ? Qt.rgba(Colours.sapphire.r, Colours.sapphire.g, Colours.sapphire.b, 0.4) : "transparent"
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

                    // Left accent bar
                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: 2
                        radius: 1
                        color: Colours.sapphire
                        opacity: row.isSelected ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 80
                            }
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
                        text: row.content
                        color: row.isSelected ? Colours.sapphire : Colours.subtext0
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeMd
                        elide: Text.ElideRight
                        Behavior on color {
                            ColorAnimation {
                                duration: 80
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
                    onClicked: {
                        copyProc.entryLine = row.entryId + "\t" + row.content;
                        copyProc.running = true;
                    }
                }
            }
        }
    }
}
