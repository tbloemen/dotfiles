//@ pragma NativeTextRendering
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "Theme"
import "Services"

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
            const open = UiState.powerMenuScreen !== "";
            UiState.closePanels();
            UiState.powerMenuScreen = open ? "" : name;
        }
        function close() {
            UiState.powerMenuScreen = "";
        }
    }

    // Notifications (Services/Notifs.qml, which also owns the D-Bus server).
    // SUPER+N clears the toasts, SUPER+SHIFT+N opens the center.
    IpcHandler {
        target: "notifications"
        function toggleCenter() {
            const name = Hyprland.focusedMonitor?.name ?? "";
            const open = UiState.notifCenterScreen !== "";
            UiState.closePanels();
            UiState.notifCenterScreen = open ? "" : name;
        }
        function clearPopups() {
            Notifs.clearPopups();
        }
        function clearAll() {
            Notifs.clearAll();
        }
        function toggleDnd() {
            Notifs.dnd = !Notifs.dnd;
        }
    }

    // The network card (NetworkCard.qml), on the focused monitor.
    IpcHandler {
        target: "network"
        function toggleCard() {
            const name = Hyprland.focusedMonitor?.name ?? "";
            const open = UiState.networkCardScreen !== "";
            UiState.closePanels();
            UiState.networkCardScreen = open ? "" : name;
        }
    }

    // The media card (MediaCard.qml), on the focused monitor, plus transport
    // controls for whichever player the card shows.
    IpcHandler {
        target: "media"
        function toggleCard() {
            const name = Hyprland.focusedMonitor?.name ?? "";
            const open = UiState.mediaCardScreen !== "";
            UiState.closePanels();
            UiState.mediaCardScreen = open ? "" : name;
        }
        function playPause() {
            Media.active?.togglePlaying();
        }
        function next() {
            Media.active?.next();
        }
        function previous() {
            Media.active?.previous();
        }
    }

    // The Bluetooth card (BluetoothCard.qml), on the focused monitor.
    IpcHandler {
        target: "bluetooth"
        function toggleCard() {
            const name = Hyprland.focusedMonitor?.name ?? "";
            const open = UiState.bluetoothCardScreen !== "";
            UiState.closePanels();
            UiState.bluetoothCardScreen = open ? "" : name;
        }
    }

    // The audio card (AudioCard.qml), on the focused monitor.
    IpcHandler {
        target: "audio"
        function toggleCard() {
            const name = Hyprland.focusedMonitor?.name ?? "";
            const open = UiState.audioCardScreen !== "";
            UiState.closePanels();
            UiState.audioCardScreen = open ? "" : name;
        }
    }

    // The calendar card (CalendarCard.qml), on the focused monitor.
    IpcHandler {
        target: "calendar"
        function toggleCard() {
            const name = Hyprland.focusedMonitor?.name ?? "";
            const open = UiState.calendarCardScreen !== "";
            UiState.closePanels();
            UiState.calendarCardScreen = open ? "" : name;
        }
    }

    // The Todoist card (TodoistCard.qml), on the focused monitor.
    IpcHandler {
        target: "todoist"
        function toggleCard() {
            const name = Hyprland.focusedMonitor?.name ?? "";
            const open = UiState.todoistCardScreen !== "";
            UiState.closePanels();
            UiState.todoistCardScreen = open ? "" : name;
        }
        function refresh() {
            Todoist.refresh();
        }
    }

    // The display card (DisplayCard.qml), SUPER+P, on the focused monitor;
    // `layout` applies a preset directly (SUPER+O: external only).
    IpcHandler {
        target: "display"
        function toggleCard() {
            const name = Hyprland.focusedMonitor?.name ?? "";
            const open = UiState.displayCardScreen !== "";
            UiState.closePanels();
            UiState.displayCardScreen = open ? "" : name;
        }
        function layout(name: string) {
            Displays.setLayout(name);
        }
    }

    // The app launcher (Launcher.qml), SUPER+SPACE. On the focused monitor.
    IpcHandler {
        target: "launcher"
        function toggle() {
            root.toggleLauncher("apps");
        }
        // SUPER+SHIFT+V: clipboard history.
        function clipboard() {
            root.toggleLauncher("clipboard");
        }
    }

    // Opens the launcher in `mode`; closes it if it's already open in that
    // mode, switches mode if it's open in the other one.
    function toggleLauncher(mode: string) {
        const name = Hyprland.focusedMonitor?.name ?? "";
        const open = UiState.launcherScreen !== "";
        if (open && UiState.launcherMode !== mode) {
            UiState.launcherMode = mode;
            return;
        }
        UiState.closePanels();
        UiState.launcherMode = mode;
        UiState.launcherScreen = open ? "" : name;
    }

    // The lock screen (LockScreen.qml). hypridle's lock_cmd calls this and
    // falls back to hyprlock unless the answer is "locked" -- so a qs that's
    // down, or running a config without this handler, still gets you locked.
    IpcHandler {
        target: "lock"
        function lock(): string {
            UiState.closePanels();
            lockScreen.lock();
            return "locked";
        }
    }

    LockScreen {
        id: lockScreen
    }

    // The polkit authentication agent; registers itself on startup.
    PolkitDialog {}

    // After repointing ~/wallpapers/active (see Services/Wallpaper.qml).
    IpcHandler {
        target: "wallpaper"
        function reload() {
            Wallpaper.reload();
        }
    }

    // hyprland.lua's brightness binds call this after brightnessctl; volume
    // needs no hook, Osd watches Pipewire itself.
    IpcHandler {
        target: "osd"
        function brightness() {
            Osd.brightness();
        }
    }

    // Singletons are created lazily on first use. The notification server
    // has to own the D-Bus name from launch, not from whenever a toast or
    // the pill first happens to touch it.
    Component.onCompleted: Notifs.popupCount

    Variants {
        model: Quickshell.screens

        // One wallpaper, bar, power menu, notification center, network card, launcher, toast window and OSD per
        // screen. They share a scope so the menus' focus grabs can whitelist
        // their own bar (see PowerMenu.qml).
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

            WallpaperWindow {
                modelData: screenScope.modelData
            }

            PowerMenu {
                modelData: screenScope.modelData
                barWindow: panel
            }

            NotificationCenter {
                modelData: screenScope.modelData
                barWindow: panel
            }

            NetworkCard {
                modelData: screenScope.modelData
                barWindow: panel
                anchorRight: bar.networkAnchorRight
            }

            Launcher {
                modelData: screenScope.modelData
                barWindow: panel
            }

            MediaCard {
                modelData: screenScope.modelData
                barWindow: panel
                anchorX: bar.mediaAnchorLeft
            }

            BluetoothCard {
                modelData: screenScope.modelData
                barWindow: panel
                anchorX: bar.bluetoothAnchorRight
            }

            AudioCard {
                modelData: screenScope.modelData
                barWindow: panel
                anchorX: bar.volumeAnchorRight
            }

            CalendarCard {
                modelData: screenScope.modelData
                barWindow: panel
                anchorX: bar.clockCenter
            }

            TodoistCard {
                modelData: screenScope.modelData
                barWindow: panel
                anchorX: bar.todoistAnchorRight
            }

            DisplayCard {
                modelData: screenScope.modelData
                barWindow: panel
                anchorX: screenScope.modelData.width / 2
            }

            NotificationPopups {
                modelData: screenScope.modelData
            }

            OsdWindow {
                modelData: screenScope.modelData
            }
        }
    }
}
