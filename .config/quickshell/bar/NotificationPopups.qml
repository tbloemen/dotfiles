import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "Theme"
import "Services"

// Notification toasts, top-right under the bar. One window per screen
// (Variants in shell.qml); only the one on Notifs.popupScreen -- the monitor
// that had focus when the latest notification arrived -- is mapped.
//
// The list repeats over *all* tracked notifications and each slot collapses
// to zero height unless its notification is currently a toast. That keeps
// one stable delegate per notification, so a toast's countdown survives
// others arriving or leaving, and showing/hiding is just an animated height.
// GridLayout rows put the newest on top.
PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property var modelData
    screen: modelData

    readonly property int cardWidth: 360
    readonly property int pad: 10 // room for the card shadow

    readonly property bool onScreen: Notifs.popupScreen === modelData.name
    readonly property bool wanted: onScreen && Notifs.popupCount > 0
    // Stay mapped a moment after the last toast goes, so it can animate out.
    property bool lingering: false
    onWantedChanged: {
        if (!wanted) {
            lingering = true;
            lingerTimer.restart();
        }
    }
    Timer {
        id: lingerTimer
        interval: Metrics.animMedium + 60
        onTriggered: root.lingering = false
    }

    // Full height, so the surface never resizes: sizing it to the cards meant
    // a Wayland resize round-trip on every frame of every slide/collapse,
    // which made the animations stutter. The mask below keeps the empty part
    // click-through.
    visible: wanted || lingering
    color: "transparent"
    anchors {
        top: true
        bottom: true
        right: true
    }
    implicitWidth: cardWidth + pad * 2
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Only the cards take input; the rest of the window clicks through.
    mask: Region {
        item: grid
    }

    GridLayout {
        id: grid
        x: root.pad
        y: root.pad
        columns: 1
        rowSpacing: 0

        Repeater {
            model: Notifs.server.trackedNotifications

            Item {
                id: slot

                required property var modelData
                required property int index

                // Starts false so a new toast slides in instead of popping.
                property bool entered: false
                Component.onCompleted: Qt.callLater(() => slot.entered = true)
                // Also gated on this window being the popup screen: when the
                // toasts move to another monitor, the ones here have to
                // animate out during `lingering` rather than stay drawn
                // until the window unmaps under them.
                readonly property bool shown: entered && root.onScreen && Notifs.popups[modelData.id] !== undefined

                Layout.row: Notifs.history.length - 1 - index
                Layout.column: 0
                Layout.preferredWidth: root.cardWidth
                Layout.preferredHeight: shown ? card.implicitHeight + Metrics.gap : 0
                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: Metrics.animMedium
                        easing.type: Easing.OutCubic
                    }
                }

                NotificationCard {
                    id: card
                    notification: slot.modelData
                    toast: true
                    active: root.visible && root.wanted
                    width: root.cardWidth
                    height: implicitHeight
                    visible: opacity > 0

                    // Slide in from the right edge; whole-pixel translate
                    // rather than a scale (see PowerMenuItem.qml's `slide`).
                    x: slot.shown ? 0 : 48
                    opacity: slot.shown ? 1 : 0
                    Behavior on x {
                        NumberAnimation {
                            duration: Metrics.animMedium
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Metrics.animMedium
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
