import QtQuick
import QtQuick.Layouts

Rectangle {
  id: btn

  property string icon: ""
  property string label: ""
  signal triggered

  Layout.fillWidth: true
  height: 44
  radius: 8
  color: "transparent"

  property bool hovered: false

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: Colours.red
    opacity: btn.hovered ? 0.15 : 0.0
    Behavior on opacity { NumberAnimation { duration: 80 } }
  }

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: "transparent"
    border.color: Colours.red
    border.width: 1
    opacity: btn.hovered ? 0.50 : 0.0
    Behavior on opacity { NumberAnimation { duration: 80 } }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: btn.hovered = true
    onExited:  btn.hovered = false
    onClicked: btn.triggered()
    cursorShape: Qt.PointingHandCursor
  }

  RowLayout {
    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
    spacing: 12

    Text {
      text: btn.icon
      font.family: Colours.fontFamily
      font.pixelSize: 18
      color: btn.hovered ? Colours.red : Colours.overlay1
      Behavior on color { ColorAnimation { duration: 80 } }
    }

    Text {
      text: btn.label
      font.family: Colours.fontFamily
      font.pixelSize: 13
      color: btn.hovered ? Colours.red : Colours.overlay1
      Layout.fillWidth: true
      Behavior on color { ColorAnimation { duration: 80 } }
    }
  }
}
