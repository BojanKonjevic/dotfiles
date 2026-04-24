import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: root
    required property var state_

    // History comes from shell.qml — plain JS array of {id, appName, appIcon, summary, body, time}
    property var notifHistory: []
    signal removeNotif(string entryId)
    signal clearAllNotifs

    anchors {
        bottom: true
        left: true
    }
    margins.left: Colours.barWidth

    implicitWidth: state_.notifPanelOpen ? Colours.panelNotif : 0
    implicitHeight: state_.notifPanelOpen ? 500 : 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    HoverHandler {
        onHoveredChanged: {
            root.state_.notifPanelHovered = hovered;
            if (!hovered)
                root.state_.notifPanelOpen = false;
        }
    }

    Rectangle {
        id: content
        anchors {
            bottom: parent.bottom
            left: parent.left
        }
        width: Colours.panelNotif - Colours.iconSizeLg
        height: root.state_.notifPanelOpen ? innerCol.implicitHeight + Colours.spacingXl : 0
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

        opacity: root.state_.notifPanelOpen ? 1.0 : 0.0
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
                margins: Colours.iconSizeSm
            }
            spacing: 0

            // ── Header ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 10

                Text {
                    text: "󰂚  Notifications"
                    color: Colours.mauve
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeSm
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }

                Text {
                    text: "󰆴"
                    color: Qt.rgba(Colours.red.r, Colours.red.g, Colours.red.b, 0.6)
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.iconSizeMd + Colours.spacingXs
                    visible: root.notifHistory.length > 0
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearAllNotifs()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, Colours.opacitySeparator)
                Layout.bottomMargin: 10
            }

            // ── Empty state ───────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: Colours.mediaArtSize - Colours.spacingMd
                visible: root.notifHistory.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "No notifications"
                    color: Colours.overlay0
                    font.family: Colours.fontFamily
                    font.pixelSize: Colours.fontSizeMd
                }
            }

            // ── Notification list ─────────────────────────────────────────
            Flickable {
                Layout.fillWidth: true
                implicitHeight: Math.min(notifCol.implicitHeight, 400)
                contentHeight: notifCol.implicitHeight
                clip: true
                visible: root.notifHistory.length > 0

                Column {
                    id: notifCol
                    width: parent.width
                    spacing: Colours.spacingSm

                    Repeater {
                        model: root.notifHistory
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: notifCol.width
                            implicitHeight: notifInner.implicitHeight + Colours.iconSizeLg
                            radius: Colours.radiusRow
                            color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.5)
                            border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.4)
                            border.width: 1

                            ColumnLayout {
                                id: notifInner
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 10
                                }
                                spacing: Colours.spacingXs

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Colours.spacingSm

                                    Image {
                                        source: modelData.appIcon !== "" ? "image://icon/" + modelData.appIcon : ""
                                        visible: modelData.appIcon !== ""
                                        width: Colours.iconSizeSm
                                        height: Colours.iconSizeSm
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: modelData.appName
                                        color: Colours.mauve
                                        font.family: Colours.fontFamily
                                        font.pixelSize: Colours.fontSizeXs
                                        font.weight: Font.Bold
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.time
                                        color: Colours.overlay0
                                        font.family: Colours.fontFamily
                                        font.pixelSize: Colours.fontSizeXs
                                    }

                                    Text {
                                        text: "✕"
                                        color: Colours.overlay1
                                        font.family: Colours.fontFamily
                                        font.pixelSize: Colours.fontSizeSm
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.removeNotif(modelData.id)
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.summary
                                    color: Colours.text
                                    font.family: Colours.fontFamily
                                    font.pixelSize: Colours.fontSizeXs
                                    font.weight: Font.Bold
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    visible: text !== ""
                                }

                                Text {
                                    text: modelData.body
                                    color: Colours.subtext0
                                    font.family: Colours.fontFamily
                                    font.pixelSize: Colours.fontSizeSm
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    textFormat: Text.RichText
                                    visible: text !== ""
                                }
                            }
                        }
                    }
                }
            }

            Item {
                implicitHeight: 2
            }
        }
    }
}
