import QtQuick
import QtQuick.Layouts

Rectangle {
    id: entry

    required property var app
    property bool selected: false
    signal clicked

    implicitHeight: Colours.spacingXl + Colours.spacingSm
    radius: Colours.radiusRow

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
        spacing: Colours.spacingMd

        Image {
            asynchronous: true
            source: entry.app.icon !== "" ? "image://icon/" + entry.app.icon : ""
            sourceSize.width: Colours.iconSizeXl
            sourceSize.height: Colours.iconSizeXl
            width: Colours.iconSizeXl
            height: Colours.iconSizeXl
            Layout.alignment: Qt.AlignVCenter
            visible: entry.app.icon !== ""
            smooth: false
            fillMode: Image.PreserveAspectFit
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: entry.app.name
                color: (entry.selected || area.containsMouse) ? Colours.mauve : Colours.text
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeMd
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: entry.app.comment || ""
                color: Colours.subtext0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeSm
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
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
