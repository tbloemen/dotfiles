import QtQuick
import "Theme"

// One row of the power menu. Reversible actions (lock, suspend) fire on a
// plain click/keypress; session-ending ones need a press-and-hold instead of
// a confirmation dialog: a fill sweeps across the row and the action only
// fires once it reaches the end. Letting go early drains it again, and a
// quick tap shakes the row and flashes "hold" in the keycap so the gesture
// explains itself.
Item {
    id: root

    required property int index
    required property var modelData
    property bool current: false
    property bool divider: false // thin rule above the row, separating groups

    readonly property bool needsHold: modelData.hold
    readonly property color accent: Colors[modelData.color]
    readonly property int rowHeight: 34
    readonly property int holdDuration: 650

    property real hold: 0 // 0..1, fill progress of a press-and-hold
    property real reveal: 1 // 0..1, staggered intro when the menu opens
    property real shake: 0 // px, horizontal nudge after a too-short tap
    // px, the row's content slides right while highlighted. A translate to a
    // whole pixel rather than a scale: the shell-wide NativeTextRendering
    // pragma rasterizes glyphs as fixed bitmaps, which smear when scaled.
    property real slide: current ? 3 : 0
    Behavior on slide {
        NumberAnimation {
            duration: Metrics.animMedium
            easing.type: Easing.OutCubic
        }
    }
    property bool holding: false
    property bool fired: false
    property bool hinting: false

    signal activated
    signal entered

    implicitHeight: rowHeight + (divider ? 9 : 0)

    function press() {
        if (fired)
            return;
        if (!needsHold) {
            fired = true;
            activated();
            return;
        }
        holding = true;
        drainAnim.stop();
        fillAnim.duration = holdDuration * (1 - hold);
        fillAnim.start();
    }

    function release() {
        if (!holding || fired)
            return;
        holding = false;
        fillAnim.stop();
        if (hold < 0.2)
            nudgeAnim.restart();
        drainAnim.start();
    }

    // Called by the menu when it closes, so a hold can't complete (and fire)
    // while the card fades out.
    function cancel() {
        fillAnim.stop();
        holding = false;
    }

    // Called by the menu every time it opens.
    function reset(staggerDelay) {
        fillAnim.stop();
        drainAnim.stop();
        hold = 0;
        holding = false;
        fired = false;
        hinting = false;
        reveal = 0;
        introPause.duration = staggerDelay;
        introAnim.restart();
    }

    NumberAnimation {
        id: fillAnim
        target: root
        property: "hold"
        to: 1
        easing.type: Easing.Linear
        onFinished: {
            if (root.hold >= 1) {
                root.fired = true;
                root.activated();
            }
        }
    }

    NumberAnimation {
        id: drainAnim
        target: root
        property: "hold"
        to: 0
        duration: 220
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: introAnim
        PauseAnimation {
            id: introPause
        }
        NumberAnimation {
            target: root
            property: "reveal"
            to: 1
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: nudgeAnim
        ScriptAction {
            script: root.hinting = true
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: -5
            duration: 45
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 5
            duration: 70
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: -3
            duration: 60
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 0
            duration: 80
            easing.type: Easing.OutCubic
        }
        PauseAnimation {
            duration: 900
        }
        ScriptAction {
            script: root.hinting = false
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 10
            rightMargin: 10
            topMargin: 4
        }
        visible: root.divider
        height: 1
        color: Colors.surface1
        opacity: root.reveal
    }

    Item {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.rowHeight

        // Hold progress. Grows from the left as a rounded pill, turns solid
        // once the action has fired.
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.fired ? parent.width : parent.width * root.hold
            visible: root.hold > 0 || root.fired
            radius: 6
            color: root.accent
            opacity: root.fired ? 1 : 0.3

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }
        }

        Item {
            id: content
            anchors.fill: parent
            opacity: root.reveal
            transform: Translate {
                x: 14 * (1 - root.reveal) + root.shake + root.slide
            }

            Text {
                id: icon
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.modelData.icon
                font.family: Metrics.iconFont
                font.pixelSize: 18
                color: root.fired ? Colors.mantle : root.current ? root.accent : Colors.overlay0

                Behavior on color {
                    ColorAnimation {
                        duration: Metrics.animFast
                    }
                }
            }

            Text {
                anchors.left: icon.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.modelData.label
                font.family: Metrics.uiFont
                font.pixelSize: Metrics.textSize
                color: root.fired ? Colors.mantle : Colors.text

                Behavior on color {
                    ColorAnimation {
                        duration: Metrics.animFast
                    }
                }
            }

            // Keycap for the shortcut letter; swaps to "hold" after a too-short
            // tap on a hold row.
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 18
                width: keyText.implicitWidth + 10
                radius: 4
                color: "transparent"
                border.width: 1
                border.color: root.hinting ? root.accent : Colors.surface1
                opacity: root.fired ? 0 : 1

                Behavior on width {
                    NumberAnimation {
                        duration: Metrics.animFast
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on border.color {
                    ColorAnimation {
                        duration: Metrics.animFast
                    }
                }

                Text {
                    id: keyText
                    anchors.centerIn: parent
                    text: root.hinting ? "hold" : root.modelData.key
                    font.family: Metrics.uiFont
                    font.pixelSize: 11
                    color: root.hinting ? root.accent : Colors.overlay0
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.entered()
            onPressed: root.press()
            onReleased: root.release()
            onCanceled: root.release()
            // Dragging off the row while holding counts as letting go.
            onContainsMouseChanged: {
                if (pressed && !containsMouse)
                    root.release();
            }
        }
    }
}
