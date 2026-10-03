pragma Singleton
import QtQuick
import Quickshell
import "../Theme"

// Which wallpaper image to show, for the desktop (../WallpaperWindow.qml)
// and the lock screen (../LockSurface.qml). Replaces hyprpaper and its
// darkman hook.
//
// ~/wallpapers/active is a symlink to a wallpapers/<name>/ directory holding
// light.png + dark.png; the frame follows Colors.mode, which darkman pushes
// over IPC, so there's no separate hook. Repoint the symlink
// (`ln -sfn other-wallpaper active` in ~/wallpapers) to switch wallpapers,
// then `qs ipc call wallpaper reload` (both frames stay loaded, so a mode
// change alone won't pick it up).
Singleton {
    id: root

    // Bumped by reload(); a different URL makes every Image load afresh
    // even though the path itself didn't change.
    property int revision: 0

    function frame(mode: string): string {
        return "file://" + Quickshell.env("HOME") + "/wallpapers/active/" + mode + ".png" + (revision > 0 ? "?" + revision : "");
    }

    readonly property string dark: frame("dark")
    readonly property string light: frame("light")
    // The frame for the current mode.
    readonly property string source: Colors.mode === "light" ? light : dark

    function reload() {
        revision++;
    }
}
