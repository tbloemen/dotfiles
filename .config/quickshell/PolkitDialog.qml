import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import "Theme"

// The session's polkit authentication agent: when something asks for admin
// rights through polkit (pkexec, systemctl from an app, mounting a disk) this
// pops a password dialog on the focused monitor. Without an agent those
// requests just fail.
//
// Unlike the cards it takes exclusive keyboard focus -- it's a modal prompt,
// and the side effect PowerMenu.qml warns about (pointer input routed to the
// layer too) is exactly what a modal wants. Enter submits, Esc cancels. The
// password field follows the lock screen's look (LockSurface.qml): dots, a
// breathing border while polkit checks, a shake when it was wrong.
Scope {
    id: root

    readonly property var flow: agent.flow
    readonly property bool active: flow !== null && !flow.isCompleted
    // Pinned to whichever monitor had focus when the request came in.
    property var targetScreen: null
    property bool checking: false

    PolkitAgent {
        id: agent
    }

    onActiveChanged: {
        if (active) {
            const name = Hyprland.focusedMonitor?.name ?? "";
            targetScreen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
            checking = false;
            input.text = "";
            openAnim.restart();
        }
    }

    Connections {
        target: root.flow
        function onIsResponseRequiredChanged() {
            if (root.flow.isResponseRequired) {
                root.checking = false;
                input.forceActiveFocus();
            }
        }
        function onFailedChanged() {
            if (root.flow.failed) {
                root.checking = false;
                input.text = "";
                shakeAnim.restart();
            }
        }
    }

    function submit() {
        if (flow === null || !flow.isResponseRequired || checking)
            return;
        checking = true;
        flow.submit(input.text);
        input.text = "";
    }

    function cancel() {
        if (flow !== null)
            flow.cancelAuthenticationRequest();
    }

    property real progress: 0
    NumberAnimation {
        id: openAnim
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: 300
        easing.type: Easing.OutExpo
    }

    property real shake: 0
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation {
            target: root
            property: "shake"
            to: -10
            duration: 50
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 10
            duration: 80
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: -6
            duration: 70
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 0
            duration: 90
            easing.type: Easing.OutCubic
        }
    }

    PanelWindow { // qmllint disable uncreatable-type
        id: window
        screen: root.targetScreen
        visible: root.active && root.targetScreen !== null
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:polkit"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Colors.crust
            opacity: 0.45 * root.progress

            // Modal: outside clicks do nothing.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }
        }

        Item {
            id: card
            anchors.centerIn: parent
            width: 380
            height: column.implicitHeight + 32
            opacity: root.progress
            scale: 0.94 + 0.06 * root.progress

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Colors.mantle
                border.width: 1
                border.color: Colors.surface1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, Colors.mode === "light" ? 0.2 : 0.5)
                    shadowBlur: 1
                    shadowVerticalOffset: 6
                }
            }

            ColumnLayout {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: 20
                        color: Colors.peach

                        Text {
                            anchors.centerIn: parent
                            text: "admin_panel_settings"
                            font.family: Metrics.iconFont
                            font.pixelSize: 22
                            color: Colors.mantle
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Authentication required"
                            font.family: Metrics.uiFont
                            font.pixelSize: 13
                            font.bold: true
                            color: Colors.text
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: root.flow?.actionId ?? ""
                            elide: Text.ElideMiddle
                            font.family: Metrics.uiFont
                            font.pixelSize: 10
                            color: Colors.overlay0
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.flow?.message ?? ""
                    wrapMode: Text.Wrap
                    font.family: Metrics.uiFont
                    font.pixelSize: 12
                    color: Colors.subtext0
                }

                Rectangle {
                    id: field
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 20
                    color: Colors.base
                    border.width: 2
                    border.color: root.checking ? Colors.peach : root.flow?.failed ? Colors.red : Colors.lavender
                    transform: Translate {
                        x: root.shake
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Metrics.animMedium
                        }
                    }

                    // Breathe while polkit is checking.
                    SequentialAnimation on opacity {
                        running: root.checking
                        loops: Animation.Infinite
                        onRunningChanged: if (!running)
                            field.opacity = 1
                        NumberAnimation {
                            to: 0.6
                            duration: 450
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: 1
                            duration: 450
                            easing.type: Easing.InOutSine
                        }
                    }

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true
                        clip: true
                        // Hidden prompts get dots like the lock screen; a
                        // visible one (rare, e.g. a username) is plain text.
                        echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        readOnly: root.checking || !(root.flow?.isResponseRequired ?? false)
                        selectByMouse: false
                        font.family: Metrics.uiFont
                        font.pixelSize: 14
                        color: Colors.text
                        onAccepted: root.submit()
                        Keys.onEscapePressed: root.cancel()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text.length === 0
                            text: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
                            font.family: Metrics.uiFont
                            font.pixelSize: 13
                            color: Colors.overlay0
                        }
                    }
                }

                // PAM's extra lines: "wrong password", lockout notices.
                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.flow?.failed && !(root.flow?.supplementaryMessage) ? "Authentication failed" : root.flow?.supplementaryMessage ?? ""
                    wrapMode: Text.Wrap
                    font.family: Metrics.uiFont
                    font.pixelSize: 11
                    color: root.flow?.failed || root.flow?.supplementaryIsError ? Colors.red : Colors.subtext0
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                    }

                    DialogButton {
                        label: "Cancel"
                        onClicked: root.cancel()
                    }

                    DialogButton {
                        label: "Authenticate"
                        primary: true
                        enabled: input.text.length > 0 && !root.checking
                        onClicked: root.submit()
                    }
                }
            }
        }
    }

    component DialogButton: Rectangle {
        id: btn
        property string label
        property bool primary: false
        signal clicked

        implicitWidth: btnText.implicitWidth + 28
        implicitHeight: 32
        radius: 16
        opacity: enabled ? 1 : 0.4
        color: primary ? Colors.peach : btnArea.containsMouse ? Colors.surface0 : "transparent"
        border.width: primary ? 0 : 1
        border.color: Colors.surface1

        Text {
            id: btnText
            anchors.centerIn: parent
            text: btn.label
            font.family: Metrics.uiFont
            font.pixelSize: 12
            font.bold: btn.primary
            color: btn.primary ? Colors.mantle : Colors.text
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
