import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "Theme"

ShellRoot {
    id: root

    // Seed the initial theme from darkman's last persisted mode so there's no
    // flash-of-wrong-theme on launch. Quickshell has no waybar-style fatal
    // @import, so unlike waybar.sh this doesn't need to run synchronously
    // before the panel appears — it's just a normal (blocking) read of a tiny
    // file at startup.
    FileView {
        id: modeFile
        path: Quickshell.env("HOME") + "/.cache/darkman/mode.txt"
        blockLoading: true
        onLoaded: {
            const m = text().trim();
            Colors.mode = m === "light" ? "light" : "dark";
        }
    }

    // Replaces .local/share/darkman/waybar.sh's colors.css swap + SIGRTMIN+8
    // signal dance. The new darkman hook (.local/share/darkman/quickshell.sh)
    // just runs: qs ipc call darkman setMode dark|light
    IpcHandler {
        target: "darkman"
        function setMode(mode: string) {
            Colors.mode = mode === "light" ? "light" : "dark";
        }
    }

    // For a keybind: qs ipc call powermenu toggle. Opens on the focused
    // monitor.
    IpcHandler {
        target: "powermenu"
        function toggle() {
            const name = Hyprland.focusedMonitor?.name ?? "";
            UiState.powerMenuScreen = UiState.powerMenuScreen === "" ? name : "";
        }
        function close() {
            UiState.powerMenuScreen = "";
        }
    }

    Variants {
        model: Quickshell.screens

        // One bar + one power menu per screen. They share a scope so the
        // menu's focus grab can whitelist its own bar (see PowerMenu.qml).
        Scope {
            id: screenScope
            required property var modelData

            PanelWindow { // qmllint disable uncreatable-type
                id: panel
                screen: screenScope.modelData
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: Metrics.barHeight
                color: "transparent"
                exclusiveZone: Metrics.barHeight

                Bar {
                    id: bar
                    anchors.fill: parent
                    screenName: screenScope.modelData.name

                    // Animation idea #5: reveal the panel on startup instead of
                    // snapping in (PanelWindow itself has no `opacity` property,
                    // so this animates the content Item instead).
                    opacity: 0
                    Component.onCompleted: revealAnim.start()
                    NumberAnimation {
                        id: revealAnim
                        target: bar
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Metrics.animSlow
                        easing.type: Easing.OutCubic
                    }
                }

                IdleInhibitor {
                    window: panel
                    enabled: UiState.idleInhibited
                }
            }

            PowerMenu {
                modelData: screenScope.modelData
                barWindow: panel
            }
        }
    }
}
