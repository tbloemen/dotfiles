import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "Theme"
import "Services"

// Notification history, unfolding out of the bar's notification pill. Same
// window/focus setup as PowerMenu.qml (see the comment there on why it's a
// HyprlandFocusGrab and not exclusive keyboard focus): one per screen, open
// when its name is in UiState.notifCenterScreen, outside click or Esc closes.
//
// Lists everything Notifs still tracks, newest first, as the same cards the
// toasts use -- default action on click, buttons, right click dismisses.
PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property var modelData
    required property PanelWindow barWindow
    screen: modelData

    readonly property bool open: UiState.notifCenterScreen === modelData.name
    property real progress: 0 // 0 closed .. 1 open
    readonly property int cardWidth: 380

    function close() {
        UiState.notifCenterScreen = "";
    }

    onOpenChanged: {
        if (open) {
            closeAnim.stop();
            Notifs.markRead();
            Notifs.clearPopups();
            Notifs.now = Date.now();
            flick.contentY = 0;
            openAnim.restart();
        } else {
            openAnim.stop();
            closeAnim.restart();
        }
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "progress"
        to: 1
        duration: 340
        easing.type: Easing.OutExpo
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "progress"
        to: 0
        duration: 170
        easing.type: Easing.InCubic
    }

    visible: open || progress > 0
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifcenter"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        windows: [root, root.barWindow]
        active: root.open
        onCleared: root.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.crust
        opacity: 0.25 * root.progress

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: root.close()
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            }
        }
    }

    Rectangle {
        id: panel

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Metrics.gap - 10 * (1 - root.progress)
        anchors.rightMargin: Metrics.gap
        width: root.cardWidth + 16
        height: header.height + body.height + 16
        radius: 10
        color: Colors.mantle
        border.width: 1
        border.color: Colors.surface1

        transformOrigin: Item.TopRight
        scale: 0.9 + 0.1 * root.progress
        opacity: root.progress

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, Colors.mode === "light" ? 0.18 : 0.45)
            shadowBlur: 0.9
            shadowVerticalOffset: 4
        }

        // Keep clicks on the panel's own padding away from the scrim.
        MouseArea {
            anchors.fill: parent
        }

        RowLayout {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            anchors.leftMargin: 12
            height: 32
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                font.family: Metrics.uiFont
                font.pixelSize: 12
                font.bold: true
                color: Colors.text
            }

            HeaderButton {
                icon: Notifs.dnd ? "notifications_off" : "notifications_active"
                label: "DND"
                accent: Notifs.dnd ? Colors.peach : Colors.overlay0
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            HeaderButton {
                icon: "clear_all"
                label: "Clear"
                accent: Colors.overlay0
                enabled: Notifs.history.length > 0
                onClicked: Notifs.clearAll()
            }
        }

        Item {
            id: body
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            anchors.topMargin: 4
            // Grow with the list, up to most of the screen, then scroll.
            height: Notifs.history.length === 0 ? 72 : Math.min(grid.implicitHeight, root.height * 0.75)

            Behavior on height {
                NumberAnimation {
                    duration: Metrics.animMedium
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                anchors.centerIn: parent
                visible: Notifs.history.length === 0
                text: "No notifications"
                font.family: Metrics.uiFont
                font.pixelSize: 12
                color: Colors.overlay0
            }

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: width
                contentHeight: grid.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                GridLayout {
                    id: grid
                    width: flick.width
                    columns: 1
                    rowSpacing: Metrics.gap

                    Repeater {
                        model: Notifs.server.trackedNotifications

                        NotificationCard {
                            required property var modelData
                            required property int index

                            notification: modelData
                            Layout.row: Notifs.history.length - 1 - index
                            Layout.column: 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            // The panel already has a shadow; stacking one
                            // per card inside it just muddies the edges.
                            shadow: false
                        }
                    }
                }
            }
        }
    }

    component HeaderButton: Rectangle {
        id: btn
        property string icon
        property string label
        property color accent
        signal clicked

        implicitWidth: btnRow.implicitWidth + 16
        implicitHeight: 26
        radius: 6
        opacity: enabled ? 1 : 0.4
        color: btnArea.containsMouse && enabled ? Colors.surface0 : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Metrics.animFast
            }
        }

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.icon
                font.family: Metrics.iconFont
                font.pixelSize: 15
                color: btn.accent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.label
                font.family: Metrics.uiFont
                font.pixelSize: 11
                color: btn.accent
            }
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (btn.enabled)
                btn.clicked()
        }
    }
}
