import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property Notification notification
    // History entry id passed in from NotificationPopups so X can remove from history
    property string historyId: ""
    signal removeNotif(string entryId)

    property color borderColor: notification.urgency === NotificationUrgency.Critical ? Qt.rgba(Colours.red.r, Colours.red.g, Colours.red.b, 0.8) : Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)

    radius: Colours.radiusPanel
    color: Qt.rgba(Colours.crust.r, Colours.crust.g, Colours.crust.b, Colours.opacityPanel)
    border.color: borderColor
    border.width: 1
    implicitHeight: inner.implicitHeight + Colours.spacingXl

    property bool dismissed: false
    visible: !dismissed

    opacity: 0
    x: -Colours.iconSizeLg
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

    // Auto-dismiss popup only — history is untouched
    Timer {
        interval: {
            const t = root.notification.expireTimeout;
            return (t > 0) ? t : 5000;
        }
        running: root.notification.urgency !== NotificationUrgency.Critical && !root.dismissed
        onTriggered: root.dismissed = true
    }

    ColumnLayout {
        id: inner
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        anchors.margins: Colours.spacingMd
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: Colours.spacingXs + Colours.spacingXs + 2

            Image {
                source: root.notification.appIcon !== "" ? "image://icon/" + root.notification.appIcon : ""
                visible: root.notification.appIcon !== ""
                width: Colours.iconSizeMd - Colours.spacingXs
                height: Colours.iconSizeMd - Colours.spacingXs
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.notification.appName
                color: Colours.mauve
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeSm
                font.weight: Font.Bold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: "✕"
                color: Colours.overlay1
                font.family: Colours.fontFamily
                font.pixelSize: Colours.fontSizeXs
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Remove from history AND dismiss the popup
                        if (root.historyId !== "")
                            root.removeNotif(root.historyId);
                        root.dismissed = true;
                    }
                }
            }
        }

        Text {
            text: root.notification.summary
            color: Colours.text
            font.family: Colours.fontFamily
            font.pixelSize: Colours.fontSizeMd
            font.weight: Font.Bold
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            visible: text !== ""
        }

        Text {
            text: root.notification.body
            color: Colours.subtext0
            font.family: Colours.fontFamily
            font.pixelSize: Colours.fontSizeXs
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            textFormat: Text.RichText
            visible: text !== ""
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colours.spacingSm
            visible: root.notification.actions.length > 0

            Repeater {
                model: root.notification.actions
                delegate: Rectangle {
                    required property var modelData
                    radius: Colours.radiusSmall
                    color: Qt.rgba(Colours.surface0.r, Colours.surface0.g, Colours.surface0.b, 0.8)
                    border.color: Qt.rgba(Colours.surface1.r, Colours.surface1.g, Colours.surface1.b, 0.5)
                    border.width: 1
                    implicitWidth: actionLabel.implicitWidth + Colours.spacingLg
                    implicitHeight: Colours.spacingXl

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData.text
                        color: Colours.text
                        font.family: Colours.fontFamily
                        font.pixelSize: Colours.fontSizeSm
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.invoke();
                            root.dismissed = true;
                        }
                    }
                }
            }
        }
    }

    // Clicking popup body just dismisses it, keeps in history
    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed = true
    }
}
