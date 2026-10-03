import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "Theme"
import "Services"

// One notification, shared by the toasts (NotificationPopups.qml) and the
// history list (NotificationCenter.qml). Mouse bindings follow what dunstrc
// had: left runs the default action (or just hides a toast), middle hides
// every toast, right dismisses the notification for good.
//
// As a toast (`toast: true`) it runs its own timeout, drawn as a thin line
// along the bottom edge that drains while it counts down and holds still
// while hovered. `active` gates the countdown: each screen has its own popup
// window, and only the one actually showing may hide the toast.
//
// The shadow lives on its own background Rectangle rather than on the card
// as a whole: a layer effect re-renders everything inside it whenever any of
// it changes, and the countdown line changes every frame.
Item {
    id: root

    required property Notification notification
    property bool toast: false
    property bool active: true
    property bool shadow: true
    property color color: Colors.base

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property color accent: critical ? Colors.red : notification.urgency === NotificationUrgency.Low ? Colors.overlay0 : Colors.mauve
    readonly property string iconSource: Notifs.iconSource(notification)
    readonly property var defaultAction: Array.from(notification.actions).find(a => a.identifier === "default") ?? null
    readonly property var buttons: Array.from(notification.actions).filter(a => a.identifier !== "default")
    readonly property bool hovered: hover.hovered

    // Bumped by Notifs whenever this notification is (re)shown as a toast.
    readonly property int serial: Notifs.popups[notification.id] ?? 0
    readonly property int timeout: Notifs.timeoutFor(notification)
    readonly property bool counting: toast && active && serial > 0 && timeout > 0
    property real life: 1 // 1..0, remaining share of the timeout

    function restartLife() {
        if (counting) {
            lifeAnim.duration = timeout;
            lifeAnim.restart();
        } else {
            lifeAnim.stop();
            life = 1;
        }
    }
    onCountingChanged: restartLife()
    onSerialChanged: restartLife()
    Component.onCompleted: restartLife()

    NumberAnimation {
        id: lifeAnim
        target: root
        property: "life"
        from: 1
        to: 0
        paused: running && root.hovered
        onFinished: Notifs.hidePopup(root.notification)
    }

    function activate() {
        if (defaultAction)
            defaultAction.invoke();
        else if (toast)
            Notifs.hidePopup(notification);
    }

    implicitHeight: content.implicitHeight + 24

    Rectangle {
        id: background
        anchors.fill: parent
        radius: 10
        color: root.color

        // Urgency accent along the left edge, following the rounded corners
        // like a CSS border-left: a pill of the card's radius in the accent
        // colour, covered by the card colour except for its leftmost 3px.
        Rectangle {
            width: background.radius * 2
            height: parent.height
            radius: background.radius
            color: root.accent
        }
        Rectangle {
            x: 3
            width: background.radius * 2
            height: parent.height
            color: background.color
        }

        // Frame on top, so it outlines the accent too.
        Rectangle {
            anchors.fill: parent
            radius: background.radius
            color: "transparent"
            border.width: 1
            border.color: root.critical ? Colors.red : Colors.surface1
        }

        layer.enabled: root.shadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, Colors.mode === "light" ? 0.18 : 0.45)
            shadowBlur: 0.9
            shadowVerticalOffset: 4
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                root.activate();
            else if (mouse.button === Qt.MiddleButton)
                Notifs.clearPopups();
            else
                root.notification.dismiss();
        }
    }

    RowLayout {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 12
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 12

        Image {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            visible: root.iconSource !== "" && status !== Image.Error
            source: root.iconSource
            sourceSize.width: 80
            sourceSize.height: 80
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: root.notification.appName + (Notifs.ageOf(root.notification) ? "  ·  " + Notifs.ageOf(root.notification) : "")
                    elide: Text.ElideRight
                    font.family: Metrics.uiFont
                    font.pixelSize: 11
                    color: Colors.overlay0
                }

                // Dismiss button, only while hovered so the header stays calm.
                Text {
                    text: "close"
                    font.family: Metrics.iconFont
                    font.pixelSize: 14
                    color: closeArea.containsMouse ? Colors.red : Colors.overlay0
                    opacity: root.hovered ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Metrics.animFast
                        }
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notification.dismiss()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification.summary
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.PlainText
                font.family: Metrics.uiFont
                font.pixelSize: Metrics.textSize
                font.bold: true
                color: Colors.text
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification.body
                wrapMode: Text.Wrap
                maximumLineCount: root.toast ? 4 : 6
                elide: Text.ElideRight
                textFormat: Text.StyledText
                linkColor: Colors.mauve
                onLinkActivated: link => Qt.openUrlExternally(link)
                font.family: Metrics.uiFont
                font.pixelSize: 12
                color: Colors.subtext0
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: root.buttons.length > 0
                spacing: 6

                Repeater {
                    model: root.buttons

                    Rectangle {
                        id: button
                        required property var modelData
                        width: label.implicitWidth + 20
                        height: 26
                        radius: 6
                        color: buttonArea.containsMouse ? Colors.surface1 : Colors.surface0
                        Behavior on color {
                            ColorAnimation {
                                duration: Metrics.animFast
                            }
                        }

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: button.modelData.text
                            font.family: Metrics.uiFont
                            font.pixelSize: 12
                            color: Colors.text
                        }

                        MouseArea {
                            id: buttonArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: button.modelData.invoke()
                        }
                    }
                }
            }
        }
    }

    // Remaining time.
    Rectangle {
        visible: root.counting
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 1
        // Clear of the rounded corners at both ends.
        anchors.leftMargin: 10
        height: 2
        width: (parent.width - 20) * root.life
        radius: 1
        color: root.accent
        opacity: 0.6
    }
}
