import QtQuick
import QtQuick.Layouts

Rectangle {
    id: btn

    property string icon: ""
    property string label: ""
    signal triggered

    Layout.fillWidth: true
    implicitHeight: Colours.powerBtnH
    implicitWidth: row.implicitWidth + Colours.spacingXl + Colours.spacingXs
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
            leftMargin: Colours.spacingMd
            rightMargin: Colours.spacingMd
        }
        spacing: 10

        Text {
            text: btn.icon
            font.family: Colours.fontFamily
            font.pixelSize: Colours.iconSizeMd
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
            font.pixelSize: Colours.fontSizeMd
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
