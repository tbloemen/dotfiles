import QtQuick
import Quickshell
import Quickshell.Wayland
import "Theme"

// The desktop wallpaper on one screen, on the background layer under
// everything (hyprpaper's job before). Services/Wallpaper.qml picks the
// frames (following the sun and darkman), WallpaperView.qml draws them.
PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Colors.crust
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:wallpaper"

    WallpaperView {
        anchors.fill: parent
    }
}
