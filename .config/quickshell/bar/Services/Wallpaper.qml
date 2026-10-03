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
// (`ln -sfn other-wallpaper active` in ~/wallpapers) to switch wallpapers:
// it shows on the next mode change, or right away with
// `qs ipc call wallpaper reload`.
Singleton {
    id: root

    // Bumped by reload(); a different URL makes every Image load afresh
    // even though the path itself didn't change.
    property int revision: 0

    readonly property string source: "file://" + Quickshell.env("HOME") + "/wallpapers/active/" + Colors.mode + ".png" + (revision > 0 ? "?" + revision : "")

    function reload() {
        revision++;
    }
}
