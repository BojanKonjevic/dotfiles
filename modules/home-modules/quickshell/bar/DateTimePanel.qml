import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root
    required property var state_

    anchors {
        top: true
        left: true
    }
    margins.left: 56

    implicitWidth: state_.dateTimeOpen ? content.width + 2 : 0
    implicitHeight: state_.dateTimeOpen ? content.height + 2 : 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    HoverHandler {
        onHoveredChanged: {
            root.state_.dateTimePanelHovered = hovered;
            if (!hovered)
                root.state_.dateTimeOpen = false;
        }
    }

    Connections {
        target: root.state_
        function onDateTimeOpenChanged() {
            if (root.state_.dateTimeOpen && !weatherProc.running)
                weatherProc.running = true;
        }
    }

    Process {
        id: weatherProc
        command: ["weather", "--panel"]
        stdout: SplitParser {
            onRead: function (data) {
                try {
                    root.state_.weatherPanel = JSON.parse(data);
                } catch (_) {}
            }
        }
    }

    Timer {
        interval: 600000
        running: root.state_.dateTimeOpen
        repeat: true
        onTriggered: {
            if (!weatherProc.running)
                weatherProc.running = true;
        }
    }

    property string panelTime: Qt.formatDateTime(new Date(), "hh:mm")
    property string panelDate: Qt.formatDateTime(new Date(), "dddd, MMMM d · yyyy")

    Timer {
        interval: 1000
        running: root.state_.dateTimeOpen
        repeat: true
        onTriggered: {
            root.panelTime = Qt.formatDateTime(new Date(), "hh:mm");
            root.panelDate = Qt.formatDateTime(new Date(), "dddd, MMMM d · yyyy");
        }
    }

    Rectangle {
        id: content
        anchors {
            top: parent.top
            left: parent.left
        }
        width: 340
        height: root.state_.dateTimeOpen ? innerCol.implicitHeight + 28 : 0
        radius: Colours.radiusPanel
        color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, Colours.opacityPanel)
        border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacityBorder)
        border.width: 1
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        opacity: root.state_.dateTimeOpen ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }

        ColumnLayout {
            id: innerCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            spacing: 0

            // ── Clock + date ─────────────────────────────────────────────────
            Text {
                text: root.panelTime
                color: Colours.mauve
                font.family: Colours.fontFamily
                font.pixelSize: 48
                font.weight: Font.Black
                Layout.topMargin: 4
            }

            Text {
                text: root.panelDate
                color: Colours.overlay1
                font.family: Colours.fontFamily
                font.pixelSize: 12
                Layout.bottomMargin: 14
            }

            // ── Current conditions ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: root.state_.weatherPanel !== null
                Layout.bottomMargin: 14

                Text {
                    text: root.state_.weatherPanel ? root.state_.weatherPanel.icon : ""
                    font.pixelSize: 40
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    spacing: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: root.state_.weatherPanel ? root.state_.weatherPanel.temp + "°C" : ""
                        color: Colours.text
                        font.family: Colours.fontFamily
                        font.pixelSize: 28
                        font.weight: Font.Black
                    }

                    Text {
                        text: root.state_.weatherPanel ? root.state_.weatherPanel.desc : ""
                        color: Colours.subtext0
                        font.family: Colours.fontFamily
                        font.pixelSize: 12
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                ColumnLayout {
                    spacing: 3
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                    RowLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignRight
                        Text {
                            text: "feels"
                            color: Colours.overlay0
                            font.family: Colours.fontFamily
                            font.pixelSize: 11
                        }
                        Text {
                            text: root.state_.weatherPanel ? root.state_.weatherPanel.feels + "°C" : ""
                            color: Colours.subtext1
                            font.family: Colours.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                    }

                    RowLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignRight
                        Text {
                            text: "💧"
                            font.pixelSize: 11
                        }
                        Text {
                            text: root.state_.weatherPanel ? root.state_.weatherPanel.humidity + "%" : ""
                            color: Colours.subtext1
                            font.family: Colours.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                    }

                    RowLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignRight
                        Text {
                            text: "💨"
                            font.pixelSize: 11
                        }
                        Text {
                            text: root.state_.weatherPanel ? root.state_.weatherPanel.wind + " km/h" : ""
                            color: Colours.subtext1
                            font.family: Colours.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                    }
                }
            }

            Text {
                text: "Fetching weather…"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: 12
                visible: root.state_.weatherPanel === null
                Layout.bottomMargin: 14
            }

            // ── Hourly strip ─────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                visible: root.state_.weatherPanel !== null
            }

            Text {
                text: "TODAY"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.topMargin: 10
                Layout.bottomMargin: 6
                visible: root.state_.weatherPanel !== null && root.state_.weatherPanel.hourly.length > 0
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                visible: root.state_.weatherPanel !== null && root.state_.weatherPanel.hourly.length > 0
                Layout.bottomMargin: 12

                Repeater {
                    model: root.state_.weatherPanel ? root.state_.weatherPanel.hourly : []
                    delegate: Item {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: hourlyCol.implicitHeight

                        ColumnLayout {
                            id: hourlyCol
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4

                            Text {
                                text: modelData.time
                                color: Colours.subtext0
                                font.family: Colours.fontFamily
                                font.pixelSize: 10
                                Layout.alignment: Qt.AlignHCenter
                                opacity: modelData.isPast ? 0.45 : 1.0
                            }

                            Text {
                                text: modelData.icon
                                font.pixelSize: 20
                                Layout.alignment: Qt.AlignHCenter
                                opacity: modelData.isPast ? 0.4 : 1.0
                            }

                            Text {
                                text: modelData.temp + "°"
                                color: modelData.isPast ? Colours.overlay0 : Colours.text
                                font.family: Colours.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                Layout.alignment: Qt.AlignHCenter
                                opacity: modelData.isPast ? 0.5 : 1.0
                            }
                        }
                    }
                }
            }

            // ── Daily forecast ────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                visible: root.state_.weatherPanel !== null
            }

            Text {
                text: "FORECAST"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.topMargin: 10
                Layout.bottomMargin: 6
                visible: root.state_.weatherPanel !== null
            }

            Repeater {
                model: root.state_.weatherPanel ? root.state_.weatherPanel.forecast : []
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: forecastRow.implicitHeight + 6
                    radius: Colours.radiusSmall
                    color: index % 2 === 0 ? Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.35) : "transparent"

                    RowLayout {
                        id: forecastRow
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: 0

                        Text {
                            text: modelData.date
                            color: index === 0 ? Colours.text : Colours.subtext0
                            font.family: Colours.fontFamily
                            font.pixelSize: 12
                            font.weight: index === 0 ? Font.Bold : Font.Normal
                            Layout.fillWidth: true
                        }

                        Item {
                            implicitWidth: 36
                            implicitHeight: iconText.implicitHeight

                            Text {
                                id: iconText
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.pixelSize: 14
                            }
                        }

                        RowLayout {
                            spacing: 4
                            Layout.minimumWidth: 76

                            Text {
                                text: modelData.high + "°"
                                color: Colours.peach
                                font.family: Colours.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                text: "/"
                                color: Colours.overlay0
                                font.family: Colours.fontFamily
                                font.pixelSize: 12
                            }

                            Text {
                                text: modelData.low + "°"
                                color: Colours.blue
                                font.family: Colours.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }
            Layout.bottomMargin: 4
        }
    }
}
