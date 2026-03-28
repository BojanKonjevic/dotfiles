import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
  id: root

  anchors { top: true; left: true; right: true }
  implicitHeight: 28
  color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, 0.60)

  // Bottom border
  Rectangle {
    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
    height: 1
    color: Qt.rgba(Colours.mauve.r, Colours.mauve.g, Colours.mauve.b, 0.35)
    z: 1
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  property string clockText:   Qt.formatDateTime(new Date(), "dd dddd hh:mm AP")
  property string weatherText: ""
  property int    cpuUsage:    0
  property int    memUsage:    0
  property string netType:     ""   // "wifi" | "ethernet" | ""
  property bool   micMuted:    false

  Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: root.clockText = Qt.formatDateTime(new Date(), "dd dddd hh:mm AP")
  }

  Process {
    id: weatherProc
    command: ["weather", "--bar"]
    stdout: SplitParser {
      onRead: function(data) {
        try { root.weatherText = JSON.parse(data).text || "" } catch (_) {}
      }
    }
  }
  Timer {
    interval: 600000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: if (!weatherProc.running) weatherProc.running = true
  }

  Process {
    id: cpuProc
    command: ["qs-cpu"]
    stdout: SplitParser {
      onRead: function(data) { root.cpuUsage = parseInt(data) || 0 }
    }
  }
  Timer {
    interval: 2000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: if (!cpuProc.running) cpuProc.running = true
  }

  Process {
    id: memProc
    command: ["qs-mem"]
    stdout: SplitParser {
      onRead: function(data) { root.memUsage = parseInt(data) || 0 }
    }
  }
  Timer {
    interval: 2000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: if (!memProc.running) memProc.running = true
  }

  Process {
    id: netProc
    command: ["qs-net"]
    stdout: SplitParser {
      onRead: function(data) { root.netType = data.trim() }
    }
  }
  Timer {
    interval: 5000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: if (!netProc.running) netProc.running = true
  }

  Process {
    id: micProc
    command: ["qs-mic"]
    stdout: SplitParser {
      onRead: function(data) { root.micMuted = data.trim() === "1" }
    }
  }
  Timer {
    interval: 1000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: if (!micProc.running) micProc.running = true
  }

  // ── Layout ────────────────────────────────────────────────────────────────
  RowLayout {
    anchors.fill: parent
    spacing: 0

    // ── Left ────────────────────────────────────────────────────────────────
    RowLayout {
      spacing: 0
      Layout.leftMargin: 4

      // Clock + right separator
      Item {
        implicitWidth: clockLabel.implicitWidth + 16
        implicitHeight: parent.height

        Text {
          id: clockLabel
          anchors.centerIn: parent
          text: root.clockText
          color: Colours.mauve
          font.family: Colours.fontFamily
          font.pixelSize: 14
          font.weight: Font.Black
        }
        Rectangle {
          anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
          width: 1
          color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.6)
        }
      }

      Text {
        text: root.weatherText
        color: Colours.text
        font.family: Colours.fontFamily
        font.pixelSize: 14
        font.weight: Font.Black
        leftPadding: 10
        visible: root.weatherText !== ""
        MouseArea {
          anchors.fill: parent
          onClicked: Quickshell.execDetached(["kitty", "--hold", "weather"])
        }
      }
    }

    Item { Layout.fillWidth: true }

    // ── Center: workspaces ───────────────────────────────────────────────────
    RowLayout {
      spacing: 0
      Repeater {
        model: 5
        delegate: WorkspaceButton {
          required property int index
          wsId: index + 1
        }
      }
    }

    Item { Layout.fillWidth: true }

    // ── Right ────────────────────────────────────────────────────────────────
    RowLayout {
      spacing: 0
      Layout.rightMargin: 4

      Text {
        text: "󰍛 " + root.cpuUsage + "%"
        color: Colours.peach
        font.family: Colours.fontFamily
        font.pixelSize: 14
        font.weight: Font.Black
        leftPadding: 8
        rightPadding: 8
      }
      Item {
        implicitWidth: memLabel.implicitWidth + 16
        implicitHeight: parent.height
        Text {
          id: memLabel
          anchors.centerIn: parent
          text: "󰾆 " + root.memUsage + "%"
          color: Colours.blue
          font.family: Colours.fontFamily
          font.pixelSize: 14
          font.weight: Font.Black
        }
        Rectangle {
          anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
          width: 1
          color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.6)
        }
      }

      Text {
        text: root.netType === "wifi"     ? "󰤨"
            : root.netType === "ethernet" ? "󰈀"
            :                               "󰤭"
        color: root.netType === "" ? Colours.overlay0 : Colours.sky
        font.family: Colours.fontFamily
        font.pixelSize: 14
        font.weight: Font.Black
        leftPadding: 8
        rightPadding: 8
        MouseArea {
          anchors.fill: parent
          onClicked: Quickshell.execDetached(["nm-connection-editor"])
        }
      }

      Text {
        text:  root.micMuted ? "󰍭" : "󰍬"
        color: root.micMuted ? Colours.red : Colours.green
        font.family: Colours.fontFamily
        font.pixelSize: 14
        font.weight: Font.Black
        leftPadding: 8
        rightPadding: 8
        MouseArea {
          anchors.fill: parent
          onClicked: {
            Quickshell.execDetached(["mic-toggle"])
            Qt.callLater(function() { if (!micProc.running) micProc.running = true })
          }
        }
      }
      Item {
        id: powerItem
        implicitWidth: powerLabel.implicitWidth + 20
        implicitHeight: parent.height
        property bool hovered: false

        Rectangle {
          anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
          width: 1
          color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.6)
        }
        Text {
          id: powerLabel
          anchors.centerIn: parent
          text: "⏻"
          font.family: Colours.fontFamily
          font.pixelSize: 14
          font.weight: Font.Black
          color: powerItem.hovered
            ? Colours.red
            : Qt.rgba(Colours.overlay1.r, Colours.overlay1.g, Colours.overlay1.b, 0.8)
          Behavior on color { ColorAnimation { duration: 100 } }
        }
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: powerItem.hovered = true
          onExited:  powerItem.hovered = false
          onClicked: Quickshell.execDetached(["power-menu"])
        }
      }
    }
  }
}
