import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "Theme"

// Shared chrome for the bar's dropdown cards (MediaCard, BluetoothCard,
// AudioCard, CalendarCard): the same window, focus and open/close animation
// NetworkCard.qml spells out inline. One per screen; open while
// UiState[screenProp] holds this screen's name. Outside click or Esc closes,
// see PowerMenu.qml on why focus is a HyprlandFocusGrab.
//
// Children go into a ColumnLayout inside the panel (use Layout.fillWidth).
// The panel unfolds from under its pill: `align` says which edge `anchorX`
// measures from -- "right" (distance to the screen's right edge), "left"
// (distance from the left edge) or "center" (the pill's center x).
PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property var modelData
    required property PanelWindow barWindow
    required property string screenProp
    required property string namespace
    property string align: "right"
    property real anchorX: Metrics.gap
    property int cardWidth: 320
    default property alias content: body.data

    readonly property bool open: UiState[screenProp] === modelData.name
    property real progress: 0 // 0 closed .. 1 open

    // Fired as the card starts opening, to reset per-open state.
    signal opened

    function close() {
        UiState[screenProp] = "";
    }

    screen: modelData

    onOpenChanged: {
        if (open) {
            closeAnim.stop();
            opened();
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
    WlrLayershell.namespace: "quickshell:" + namespace
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

    Item {
        id: panel

        readonly property real maxX: root.width - width - Metrics.gap
        // Line up with the pill, but keep the whole card on screen.
        x: Math.round(Math.max(Metrics.gap, Math.min(maxX, root.align === "right" ? root.width - root.anchorX - width : root.align === "left" ? root.anchorX : root.anchorX - width / 2)))
        y: Metrics.gap - 10 * (1 - root.progress)
        width: root.cardWidth + 16
        height: body.implicitHeight + 16

        transformOrigin: root.align === "right" ? Item.TopRight : root.align === "left" ? Item.TopLeft : Item.Top
        scale: 0.9 + 0.1 * root.progress
        opacity: root.progress

        // The shadow sits on a background of its own: a layer on the whole
        // card would render the text into a texture and resample it, which
        // blurs it.
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Colors.mantle
            border.width: 1
            border.color: Colors.surface1
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, Colors.mode === "light" ? 0.18 : 0.45)
                shadowBlur: 0.9
                shadowVerticalOffset: 4
            }
        }

        // Keep clicks on the panel's own padding away from the scrim.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: body
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            spacing: 8
        }
    }
}
