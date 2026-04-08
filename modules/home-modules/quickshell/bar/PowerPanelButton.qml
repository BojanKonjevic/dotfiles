import QtQuick
import QtQuick.Layouts

Rectangle {
    id: btn

    property string icon: ""
    property string label: ""
    signal triggered

    Layout.fillWidth: true
    implicitHeight: 40
    implicitWidth: row.implicitWidth + 28
    radius: Colours.radiusRow
    color: "transparent"

    property bool hovered: false

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Colours.red
        opacity: btn.hovered ? 0.12 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 80
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: Colours.red
        border.width: 1
        opacity: btn.hovered ? 0.45 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 80
            }
        }
    }

    RowLayout {
        id: row
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 10

        Text {
            text: btn.icon
            font.family: Colours.fontFamily
            font.pixelSize: 16
            color: btn.hovered ? Colours.red : Colours.overlay1
            Behavior on color {
                ColorAnimation {
                    duration: 80
                }
            }
        }

        Text {
            text: btn.label
            font.family: Colours.fontFamily
            font.pixelSize: 13
            color: btn.hovered ? Colours.red : Colours.overlay1
            Layout.fillWidth: true
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
        onEntered: btn.hovered = true
        onExited: btn.hovered = false
        onClicked: btn.triggered()
        cursorShape: Qt.PointingHandCursor
    }
}
