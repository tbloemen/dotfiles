import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.UPower
import "Theme"

// What one monitor shows while locked (see LockScreen.qml, which owns the
// lock, PAM and the state every screen shares). Laid out like the old
// hyprlock.conf: big clock and date above center, password field below, over
// a blurred and dimmed copy of the wallpaper -- the darkman-driven one
// hyprpaper shows (~/.cache/hyprpaper/current.png), so the lock follows
// light/dark like everything else.
//
// The real input is an invisible TextInput; the field draws one dot per
// character instead, so nothing about the password's content is rendered.
// Enter submits, Esc clears.
Item {
    id: root

    required property var context

    property date now: new Date()
    property real reveal: 0 // 0..1, fade/slide in on lock
    property real shake: 0

    opacity: context.unlocking ? 0 : reveal
    Behavior on opacity {
        enabled: root.context.unlocking
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: revealAnim.start()

    NumberAnimation {
        id: revealAnim
        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: 450
        easing.type: Easing.OutCubic
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Connections {
        target: root.context
        function onFailed() {
            shakeAnim.restart();
        }
        function onPasswordChanged() {
            if (input.text !== root.context.password)
                input.text = root.context.password;
        }
    }

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

    Rectangle {
        anchors.fill: parent
        color: Colors.crust
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.cache/hyprpaper/current.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // The symlink is swapped by darkman; always read the current target.
        cache: false
        visible: false
    }

    // Blur is sampled past the edges as transparent; scaling up a touch hides
    // the darkened rim that leaves.
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        scale: 1.06
        blurEnabled: true
        blur: 1
        blurMax: 48
        opacity: wallpaper.status === Image.Ready ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.crust
        opacity: Colors.mode === "light" ? 0.35 : 0.5
    }

    Item {
        id: content
        anchors.fill: parent
        transform: Translate {
            y: Math.round(24 * (1 - root.reveal))
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: 40
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(root.now, "HH:mm")
                font.family: Metrics.uiFont
                font.pixelSize: 120
                font.weight: Font.ExtraBold
                color: Colors.text
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(root.now, "dddd d MMMM")
                font.family: Metrics.uiFont
                font.pixelSize: 22
                color: Colors.subtext0
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 60
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Quickshell.env("USER")
                font.family: Metrics.uiFont
                font.pixelSize: 13
                font.bold: true
                color: Colors.subtext0
            }

            Rectangle {
                id: field
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300
                height: 50
                radius: height / 2
                color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.75)
                border.width: 2
                border.color: root.context.authenticating ? Colors.peach : root.context.message !== "" && root.context.password === "" ? Colors.red : input.activeFocus ? Colors.lavender : Colors.surface1
                transform: Translate {
                    x: root.shake
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: Metrics.animMedium
                    }
                }

                // Breathe while PAM is checking.
                SequentialAnimation on opacity {
                    running: root.context.authenticating
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
                    focus: true
                    opacity: 0
                    echoMode: TextInput.Password
                    readOnly: root.context.authenticating || root.context.unlocking
                    // Never let anything be dragged or pasted out of it.
                    selectByMouse: false
                    onTextChanged: root.context.password = text
                    onAccepted: root.context.submit()
                    Keys.onEscapePressed: root.context.password = ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.context.password === ""
                    text: root.context.message !== "" ? root.context.message : "Password"
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.family: Metrics.uiFont
                    font.pixelSize: 13
                    color: root.context.message !== "" ? Colors.red : Colors.overlay0
                }

                Row {
                    id: dots
                    anchors.centerIn: parent
                    spacing: 8
                    // Past what fits, the dots stop growing and just stay full.
                    readonly property int maxDots: Math.floor((field.width - 40 + spacing) / (10 + spacing))

                    Repeater {
                        model: Math.min(root.context.password.length, dots.maxDots)

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: Colors.text
                            scale: 0
                            Component.onCompleted: scale = 1
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutBack
                                }
                            }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.context.failures > 0
                text: root.context.failures + (root.context.failures === 1 ? " failed attempt" : " failed attempts")
                font.family: Metrics.uiFont
                font.pixelSize: 11
                color: Colors.overlay0
            }
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 24
            spacing: 6
            visible: UPower.displayDevice.isLaptopBattery

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: UPower.displayDevice.state === 1 ? "battery_charging_full" : "battery_full"
                font.family: Metrics.iconFont
                font.pixelSize: 18
                color: Colors.subtext0
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(UPower.displayDevice.percentage * 100) + "%"
                font.family: Metrics.uiFont
                font.pixelSize: 13
                color: Colors.subtext0
            }
        }
    }
}
