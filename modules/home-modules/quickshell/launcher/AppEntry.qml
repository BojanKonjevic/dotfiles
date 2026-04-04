import QtQuick
import QtQuick.Layouts

Rectangle {
    id: entry

    required property var app
    property bool selected: false
    signal clicked

    implicitHeight: visible ? row.implicitHeight + 12 : 0
    height: implicitHeight
    clip: true
    radius: 8

    color: (selected || hovered) ? Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.15) : "transparent"
    border.color: (selected || hovered) ? Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.4) : "transparent"
    border.width: 1

    property bool hovered: false
    Behavior on color {
        ColorAnimation {
            duration: 80
        }
    }

    RowLayout {
        id: row
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 12

        Image {
            source: entry.app.icon !== "" ? "image://icon/" + entry.app.icon : ""
            sourceSize.width: 28
            sourceSize.height: 28
            width: 28
            height: 28
            Layout.alignment: Qt.AlignVCenter
            visible: entry.app.icon !== ""
            smooth: true
            fillMode: Image.PreserveAspectFit
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: entry.app.name
                color: (entry.selected || entry.hovered) ? Colours.mauve : Colours.text
                font.family: Colours.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
                Behavior on color {
                    ColorAnimation {
                        duration: 80
                    }
                }
            }

            Text {
                text: entry.app.comment || ""
                color: Colours.subtext0
                font.family: Colours.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: entry.hovered = true
        onExited: entry.hovered = false
        onClicked: entry.clicked()
    }
}
