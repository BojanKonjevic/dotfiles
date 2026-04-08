import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property Notification notification

    // Urgency-based border: critical gets red, normal gets surface1
    property color borderColor: notification.urgency === NotificationUrgency.Critical ? Qt.rgba(Colours.red.r, Colours.red.g, Colours.red.b, 0.8) : Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)

    radius: Colours.radiusPanel
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, Colours.opacityPanel)
    border.color: borderColor
    border.width: 1
    implicitHeight: inner.implicitHeight + 24

    // Slide in from the right
    opacity: 0
    x: 20
    Component.onCompleted: {
        opacity = 1;
        x = 0;
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }
    Behavior on x {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    // Auto-dismiss — respect the notification's own timeout, default 5 s
    Timer {
        interval: {
            const t = root.notification.expireTimeout;
            return (t > 0) ? t : 5000;
        }
        running: root.notification.urgency !== NotificationUrgency.Critical
        onTriggered: root.notification.tracked = false
    }

    ColumnLayout {
        id: inner
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        anchors.margins: 12
        spacing: 4

        // ── Header row ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // App icon (if present)
            Image {
                source: root.notification.appIcon !== "" ? "image://icon/" + root.notification.appIcon : ""
                visible: root.notification.appIcon !== ""
                width: 16
                height: 16
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.notification.appName
                color: Colours.mauve
                font.family: Colours.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: "✕"
                color: Colours.overlay1
                font.family: Colours.fontFamily
                font.pixelSize: 12
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.notification.tracked = false
                }
            }
        }

        // ── Summary ─────────────────────────────────────────────────────────────
        Text {
            text: root.notification.summary
            color: Colours.text
            font.family: Colours.fontFamily
            font.pixelSize: 13
            font.weight: Font.Bold
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            visible: text !== ""
        }

        // ── Body ────────────────────────────────────────────────────────────────
        Text {
            text: root.notification.body
            color: Colours.subtext0
            font.family: Colours.fontFamily
            font.pixelSize: 12
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            textFormat: Text.RichText
            visible: text !== ""
        }

        // ── Actions ─────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.notification.actions.length > 0

            Repeater {
                model: root.notification.actions
                delegate: Rectangle {
                    required property var modelData
                    radius: 6
                    color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.8)
                    border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)
                    border.width: 1
                    implicitWidth: actionLabel.implicitWidth + 16
                    implicitHeight: 24

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData.text
                        color: Colours.text
                        font.family: Colours.fontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.invoke();
                            root.notification.tracked = false;
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.notification.tracked = false
    }
}
