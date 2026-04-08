import QtQuick
import QtQuick.Layouts

Rectangle {
    id: entry

    required property var app
    property bool selected: false
    signal clicked

    implicitHeight: 44
    radius: Colours.radiusRow

    // No Behavior — direct color assignment is instant and avoids
    // per-item animation timers multiplied across every visible row
    color: (selected || area.containsMouse) ? Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.15) : "transparent"
    border.color: (selected || area.containsMouse) ? Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.4) : "transparent"
    border.width: 1

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 12

        Image {
            // asynchronous so icon loading never blocks the UI thread
            asynchronous: true
            source: entry.app.icon !== "" ? "image://icon/" + entry.app.icon : ""
            sourceSize.width: 28
            sourceSize.height: 28
            width: 28
            height: 28
            Layout.alignment: Qt.AlignVCenter
            visible: entry.app.icon !== ""
            smooth: false  // nearest-neighbour is faster for small icons
            fillMode: Image.PreserveAspectFit
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: entry.app.name
                // No Behavior — same reason as above
                color: (entry.selected || area.containsMouse) ? Colours.mauve : Colours.text
                font.family: Colours.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: entry.app.comment || ""
                color: Colours.subtext0
                font.family: Colours.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
                // fixed height avoids re-layout when comment appears/disappears
                height: visible ? implicitHeight : 0
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: entry.clicked()
    }
}
