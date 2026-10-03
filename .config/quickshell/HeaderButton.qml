import QtQuick
import "Theme"

// Small icon + label button for a card's header row (NotificationCenter.qml,
// NetworkCard.qml). Flat until hovered; dims when disabled.
Rectangle {
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
            visible: btn.label.length > 0
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
