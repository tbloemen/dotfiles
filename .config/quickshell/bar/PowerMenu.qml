import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "Theme"

// Power menu, replacing the rofi powermenu.sh the bar's power pill used to
// launch. A small card that unfolds out of the power pill, top-right, rather
// than a centered dialog: five rows, single gesture each. Lock and suspend
// fire on click; log out / reboot / shut down are press-and-hold (see
// PowerMenuItem.qml) so there's no separate confirmation step.
//
// One instance per screen (Variants in shell.qml); only the one whose name
// is in UiState.powerMenuScreen is open. The window is an overlay over
// everything below the bar(s) -- it respects exclusive zones rather than
// hardcoding the bar height, so it never covers the power pill.
//
// Keyboard focus comes from a HyprlandFocusGrab, not WlrKeyboardFocus
// .Exclusive: while a layer holds exclusive focus Hyprland routes *pointer*
// input to it too, so the bar (and the power pill's close toggle) went dead.
// The grab whitelists this screen's bar, and any click outside both windows
// clears it, which closes the menu. Shortcuts:
//   l s e r p  pick a row (hold the key for hold rows)
//   ↑↓ / j k / Tab  move, Enter/Space  activate, Esc  close
PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property var modelData
    required property PanelWindow barWindow
    screen: modelData

    readonly property bool open: UiState.powerMenuScreen === modelData.name
    property real progress: 0 // 0 closed .. 1 open, drives the card transition
    property int currentIndex: 0
    property int keyHeldIndex: -1
    property var pendingCommand: []
    property string uptime: ""

    readonly property var actions: [
        {
            key: "l",
            icon: "lock",
            label: "Lock",
            color: "teal",
            hold: false,
            // Via logind so it takes the same path as hypridle's idle timeout.
            command: ["loginctl", "lock-session"]
        },
        {
            key: "s",
            icon: "bedtime",
            label: "Suspend",
            color: "mauve",
            hold: false,
            // hypridle's before_sleep_cmd locks the session on the way down.
            command: ["systemctl", "suspend"]
        },
        {
            key: "e",
            icon: "logout",
            label: "Log out",
            color: "yellow",
            hold: true,
            // Same hyprshutdown-first fallback as the SUPER+M bind; the
            // fallback must be the Lua dispatcher, see CLAUDE.md.
            command: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && exec hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"]
        },
        {
            key: "r",
            icon: "restart_alt",
            label: "Reboot",
            color: "peach",
            hold: true,
            command: ["systemctl", "reboot"]
        },
        {
            key: "p",
            icon: "power_settings_new",
            label: "Shut down",
            color: "red",
            hold: true,
            command: ["systemctl", "poweroff"]
        }
    ]

    function close() {
        UiState.powerMenuScreen = "";
    }

    // Close first, run once the card is gone: suspending with the menu still
    // up would leave it on screen (mid-fade) after resume.
    function run(command) {
        pendingCommand = command;
        close();
    }

    function itemAt(i) {
        return i >= 0 && i < rows.count ? rows.itemAt(i) : null;
    }

    function move(delta) {
        currentIndex = (currentIndex + delta + actions.length) % actions.length;
    }

    function indexForKey(key) {
        const ch = String.fromCharCode(key).toLowerCase();
        return actions.findIndex(a => a.key === ch);
    }

    onOpenChanged: {
        if (open) {
            closeAnim.stop();
            currentIndex = 0;
            keyHeldIndex = -1;
            pendingCommand = [];
            uptimeProc.running = true;
            for (let i = 0; i < rows.count; i++)
                rows.itemAt(i).reset(60 + i * 28);
            openAnim.restart();
        } else {
            for (let i = 0; i < rows.count; i++)
                rows.itemAt(i).cancel();
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
        onFinished: {
            if (root.pendingCommand.length > 0) {
                Quickshell.execDetached(root.pendingCommand);
                root.pendingCommand = [];
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = Math.floor(parseFloat(text.split(" ")[0]));
                const d = Math.floor(s / 86400);
                const h = Math.floor(s % 86400 / 3600);
                const m = Math.floor(s % 3600 / 60);
                root.uptime = "up " + (d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m");
            }
        }
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
    WlrLayershell.namespace: "quickshell:powermenu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        windows: [root, root.barWindow]
        active: root.open
        onCleared: root.close()
    }

    // Faint scrim: mostly there to catch outside clicks, dim just enough to
    // pull the eye to the card.
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
            event.accepted = true;
            // Escape always wins, even mid-hold.
            if (event.key === Qt.Key_Escape) {
                root.close();
                return;
            }
            if (event.isAutoRepeat || root.keyHeldIndex !== -1)
                return;
            switch (event.key) {
            case Qt.Key_Up:
            case Qt.Key_K:
            case Qt.Key_Backtab:
                root.move(-1);
                return;
            case Qt.Key_Down:
            case Qt.Key_J:
            case Qt.Key_Tab:
                root.move(1);
                return;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                root.keyHeldIndex = root.currentIndex;
                break;
            default:
                {
                    const i = root.indexForKey(event.key);
                    if (i === -1) {
                        event.accepted = false;
                        return;
                    }
                    root.currentIndex = i;
                    root.keyHeldIndex = i;
                }
            }
            root.itemAt(root.keyHeldIndex).press();
        }

        Keys.onReleased: event => {
            if (event.isAutoRepeat || root.keyHeldIndex === -1)
                return;
            const item = root.itemAt(root.keyHeldIndex);
            root.keyHeldIndex = -1;
            item.release();
        }
    }

    Item {
        id: card

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Metrics.gap - 10 * (1 - root.progress)
        anchors.rightMargin: Metrics.gap
        width: 224
        height: column.implicitHeight + 12

        // Unfold out of the power pill, which sits right above the card's
        // top-right corner.
        transformOrigin: Item.TopRight
        scale: 0.9 + 0.1 * root.progress
        opacity: root.progress

        // The shadow sits on a background of its own: a layer on the whole
        // card would render the text into a texture and resample it, which
        // blurs it.
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Colors.base
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

        // Swallow clicks on the card's own padding so they don't reach the
        // scrim and close the menu.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6

            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: Quickshell.env("USER")
                    font.family: Metrics.uiFont
                    font.pixelSize: 11
                    font.bold: true
                    color: Colors.overlay0
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.uptime
                    font.family: Metrics.uiFont
                    font.pixelSize: 11
                    color: Colors.overlay0
                }
            }

            Item {
                width: parent.width
                height: list.implicitHeight

                // One shared highlight that glides between rows, for both
                // hover and keyboard navigation.
                Rectangle {
                    readonly property Item target: root.itemAt(root.currentIndex)
                    x: 0
                    width: parent.width
                    height: 34
                    y: target ? target.y + target.height - height : 0
                    radius: 6
                    color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
                    opacity: target ? 1 : 0

                    Behavior on y {
                        NumberAnimation {
                            duration: Metrics.animMedium
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Column {
                    id: list
                    width: parent.width

                    Repeater {
                        id: rows
                        model: root.actions

                        PowerMenuItem {
                            width: list.width
                            current: index === root.currentIndex
                            // Separate the reversible actions from the
                            // session-ending ones.
                            divider: index === 2
                            onEntered: root.currentIndex = index
                            onActivated: root.run(modelData.command)
                        }
                    }
                }
            }
        }
    }
}
