import QtQuick
import "Theme"

// Thin horizontal slider for the cards (volumes in AudioCard.qml, the seek
// bar in MediaCard.qml). `value` is 0..1 and comes from outside; dragging,
// clicking or scrolling emits `moved` with the new value, and while a drag
// is in progress the knob follows the pointer instead of `value`.
Item {
    id: root

    property real value: 0
    property color accent: Colors.lavender
    property real wheelStep: 0.05

    signal moved(real value)

    readonly property bool dragging: area.pressed
    property real dragValue: 0
    readonly property real shown: Math.max(0, Math.min(1, dragging ? dragValue : value))

    implicitHeight: 18
    implicitWidth: 120
    opacity: enabled ? 1 : 0.4

    function valueAt(x: real): real {
        return Math.max(0, Math.min(1, (x - knob.width / 2) / (width - knob.width)));
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: Colors.surface0

        Rectangle {
            width: knob.x + knob.width / 2
            height: parent.height
            radius: parent.radius
            color: root.accent
        }
    }

    Rectangle {
        id: knob
        anchors.verticalCenter: parent.verticalCenter
        x: root.shown * (root.width - width)
        width: area.containsMouse || root.dragging ? 14 : 10
        height: width
        radius: width / 2
        color: root.accent

        Behavior on width {
            NumberAnimation {
                duration: Metrics.animFast
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: mouse => {
            root.dragValue = root.valueAt(mouse.x);
            root.moved(root.dragValue);
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            root.dragValue = root.valueAt(mouse.x);
            root.moved(root.dragValue);
        }
        onWheel: wheel => {
            const next = Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep)));
            root.moved(next);
        }
    }
}
