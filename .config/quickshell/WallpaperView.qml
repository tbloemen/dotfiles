import QtQuick
import "Theme"
import "Services"

// Draws what Services/Wallpaper.qml picks: its `lower` frame with `upper`
// blended over it. Used by the desktop (WallpaperWindow.qml) and the lock
// screen (LockSurface.qml).
//
// The minute-by-minute blend changes in place. When the pair of frames itself
// changes -- passing a frame, a manual darkman toggle, a reload -- the new pair
// loads into the other of two layers and fades in over the old one only once
// its images have decoded, so there's never a flash of the background. The
// fade takes Metrics.animTheme, in step with the bar's colors on a toggle.
Item {
    id: root

    // Every layer's images are ready (for the lock screen's blur fade-in).
    readonly property bool ready: front.ready && front.lower !== ""

    property Layer front: a
    property Layer back: b

    component Frame: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        // Decode at screen size rather than the full image: a 3200x1800
        // frame otherwise sits in memory for no visible gain.
        sourceSize.width: width
        sourceSize.height: height
        asynchronous: true
        // The same path can hold a different file (the active symlink gets
        // repointed).
        cache: false
    }

    component Layer: Item {
        id: layer

        property string lower: ""
        property string upper: ""
        property real blend: 0
        readonly property string key: lower + "|" + upper
        readonly property bool ready: lowerImage.status === Image.Ready && (upper === "" || upperImage.status === Image.Ready)

        anchors.fill: parent

        Frame {
            id: lowerImage
            source: layer.lower
        }

        Frame {
            id: upperImage
            source: layer.upper
            opacity: layer.blend
            // Smooths the jump after a resume from suspend; the regular
            // minute steps are too small to see either way.
            Behavior on opacity {
                enabled: layer === root.front
                NumberAnimation {
                    duration: Metrics.animTheme
                    easing.type: Metrics.animThemeEasing
                }
            }
        }
    }

    Layer {
        id: a
    }

    Layer {
        id: b
        opacity: 0
    }

    function sync() {
        const key = Wallpaper.lower + "|" + Wallpaper.upper;
        if (key === front.key) {
            front.blend = Wallpaper.blend;
            if (!fade.running && back.lower !== "") {
                // Changed back to what's shown while the other pair was still
                // loading.
                back.lower = back.upper = "";
            }
            return;
        }
        if (fade.running)
            return; // onFinished syncs again
        back.lower = Wallpaper.lower;
        back.upper = Wallpaper.upper;
        back.blend = Wallpaper.blend;
        tryFade();
    }

    function tryFade() {
        if (fade.running || !back.ready || back.lower === "")
            return;
        back.z = 1;
        front.z = 0;
        fade.target = back;
        fade.start();
    }

    NumberAnimation {
        id: fade
        property: "opacity"
        from: 0
        to: 1
        duration: Metrics.animTheme
        easing.type: Metrics.animThemeEasing
        onFinished: {
            const old = root.front;
            root.front = root.back;
            root.back = old;
            old.opacity = 0;
            // Free the old pair's decoded images.
            old.lower = old.upper = "";
            root.sync();
        }
    }

    Connections {
        target: root.back
        function onReadyChanged() {
            root.tryFade();
        }
    }

    Connections {
        target: Wallpaper
        function onLowerChanged() {
            Qt.callLater(root.sync);
        }
        function onUpperChanged() {
            Qt.callLater(root.sync);
        }
        function onBlendChanged() {
            Qt.callLater(root.sync);
        }
    }

    Component.onCompleted: sync()
}
