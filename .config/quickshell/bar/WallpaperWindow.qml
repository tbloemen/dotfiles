import QtQuick
import Quickshell
import Quickshell.Wayland
import "Theme"
import "Services"

// The desktop wallpaper on one screen, on the background layer under
// everything (hyprpaper's job before). The images come from
// Services/Wallpaper.qml and follow darkman.
//
// Both frames stay loaded, with the light one fading in over the dark one,
// so a mode change starts crossfading immediately -- in step with the bar's
// colors (same Metrics.animTheme) -- instead of first waiting on a decode.
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

    component Frame: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        // Decode at screen size rather than the full image: two of these per
        // screen at 3200x1800 otherwise sit in memory for no visible gain.
        sourceSize.width: width
        sourceSize.height: height
        asynchronous: true
        // The same path can hold a different file (the active symlink gets
        // repointed).
        cache: false
    }

    Frame {
        source: Wallpaper.dark
    }

    Frame {
        source: Wallpaper.light
        opacity: Colors.mode === "light" ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Metrics.animTheme
                easing.type: Metrics.animThemeEasing
            }
        }
    }
}
