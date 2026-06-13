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
    margins.left: Colours.barWidth

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
        width: Colours.panelDateTime
        height: root.state_.dateTimeOpen ? innerCol.implicitHeight + Colours.spacingXl : 0
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
                margins: Colours.spacingLg
            }
            spacing: 0

            // ── Clock + date ─────────────────────────────────────────────────
            Text {
                text: root.panelTime
                color: Colours.mauve
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSize3Xl
                font.weight: Font.Black
                Layout.topMargin: 4
            }

            Text {
                text: root.panelDate
                color: Colours.overlay1
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeXs
                Layout.bottomMargin: Colours.iconSizeSm
            }

            // ── Current conditions ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: root.state_.weatherPanel !== null
                Layout.bottomMargin: Colours.iconSizeSm

                Text {
                    text: root.state_.weatherPanel ? root.state_.weatherPanel.icon : ""
                    font.pixelSize: Colours.fontSize2Xl + Colours.spacingMd
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    spacing: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: root.state_.weatherPanel ? root.state_.weatherPanel.temp + "°C" : ""
                        color: Colours.text
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSize2Xl
                        font.weight: Font.Black
                    }

                    Text {
                        text: root.state_.weatherPanel ? root.state_.weatherPanel.desc : ""
                        color: Colours.subtext0
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeXs
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                ColumnLayout {
                    spacing: Colours.spacingXs
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                    RowLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignRight
                        Text {
                            text: "feels"
                            color: Colours.overlay0
                            font.family: Colours.fontFamily
                            font.pixelSize: Colours.fontSizeSm
                        }
                        Text {
                            text: root.state_.weatherPanel ? root.state_.weatherPanel.feels + "°C" : ""
                            color: Colours.subtext1
                            font.family: Colours.fontFamily
                            font.pixelSize: Colours.fontSizeSm
                            font.weight: Font.Bold
                        }
                    }

                    RowLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignRight
                        Text {
                            text: "💧"
                            font.pixelSize: Colours.fontSizeSm
                        }
                        Text {
                            text: root.state_.weatherPanel ? root.state_.weatherPanel.humidity + "%" : ""
                            color: Colours.subtext1
                            font.family: Colours.fontFamily
                            font.pixelSize: Colours.fontSizeSm
                            font.weight: Font.Bold
                        }
                    }

                    RowLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignRight
                        Text {
                            text: "💨"
                            font.pixelSize: Colours.fontSizeSm
                        }
                        Text {
                            text: root.state_.weatherPanel ? root.state_.weatherPanel.wind + " km/h" : ""
                            color: Colours.subtext1
                            font.family: Colours.fontFamily
                            font.pixelSize: Colours.fontSizeSm
                            font.weight: Font.Bold
                        }
                    }
                }
            }

            Text {
                text: "Fetching weather…"
                color: Colours.overlay0
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeXs
                visible: root.state_.weatherPanel === null
                Layout.bottomMargin: Colours.iconSizeSm
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
                font.pixelSize: Colours.fontSizeXs
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.topMargin: 10
                Layout.bottomMargin: Colours.spacingSm
                visible: root.state_.weatherPanel !== null && root.state_.weatherPanel.hourly.length > 0
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                visible: root.state_.weatherPanel !== null && root.state_.weatherPanel.hourly.length > 0
                Layout.bottomMargin: Colours.spacingMd

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
                                font.pixelSize: Colours.fontSizeXs
                                Layout.alignment: Qt.AlignHCenter
                                opacity: modelData.isPast ? 0.45 : 1.0
                            }

                            Text {
                                text: modelData.icon
                                font.pixelSize: Colours.iconSizeLg
                                Layout.alignment: Qt.AlignHCenter
                                opacity: modelData.isPast ? 0.4 : 1.0
                            }

                            Text {
                                text: modelData.temp + "°"
                                color: modelData.isPast ? Colours.overlay0 : Colours.text
                                font.family: Colours.fontFamily
                                font.pixelSize: Colours.fontSizeMd
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
                font.pixelSize: Colours.fontSizeXs
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.topMargin: 10
                Layout.bottomMargin: Colours.spacingSm
                visible: root.state_.weatherPanel !== null
            }

            Repeater {
                model: root.state_.weatherPanel ? root.state_.weatherPanel.forecast : []
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: forecastRow.implicitHeight + Colours.spacingSm
                    radius: Colours.radiusSmall
                    color: index % 2 === 0 ? Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.35) : "transparent"

                    RowLayout {
                        id: forecastRow
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: Colours.spacingXs + Colours.spacingXs + 2
                            rightMargin: Colours.spacingXs + Colours.spacingXs + 2
                        }
                        spacing: 0

                        Text {
                            text: modelData.date
                            color: index === 0 ? Colours.text : Colours.subtext0
                            font.family: Colours.fontFamily
                            font.pixelSize: Colours.fontSizeXs
                            font.weight: index === 0 ? Font.Bold : Font.Normal
                            Layout.fillWidth: true
                        }

                        Item {
                            implicitWidth: Colours.spacingXl + Colours.spacingSm
                            implicitHeight: iconText.implicitHeight

                            Text {
                                id: iconText
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.pixelSize: Colours.iconSizeSm
                            }
                        }

                        RowLayout {
                            spacing: 4
                            Layout.minimumWidth: Colours.spacingXl * 3 + Colours.spacingSm

                            Text {
                                text: modelData.high + "°"
                                color: Colours.peach
                                font.family: Colours.fontFamily
                                font.pixelSize: Colours.fontSizeXs
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                text: "/"
                                color: Colours.overlay0
                                font.family: Colours.fontFamily
                                font.pixelSize: Colours.fontSizeXs
                            }

                            Text {
                                text: modelData.low + "°"
                                color: Colours.blue
                                font.family: Colours.fontFamily
                                font.pixelSize: Colours.fontSizeXs
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
