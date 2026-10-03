import QtQuick
import Quickshell
import Quickshell.Wayland
import "Theme"
import "Services"

// The desktop wallpaper on one screen, on the background layer under
// everything (hyprpaper's job before). The image comes from
// Services/Wallpaper.qml and follows darkman; a change crossfades instead of
// cutting.
//
// Two images, `back` and `front`, with only `front`'s opacity animating: the
// new image loads into whichever one is hidden, and once it's ready `front`
// fades in over `back` or out to reveal it.
PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property var modelData
    screen: modelData

    readonly property string source: Wallpaper.source
    property bool showFront: false

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

    function load() {
        const target = showFront ? back : front;
        target.source = source;
        loaded(target);
    }

    onSourceChanged: load()
    Component.onCompleted: load()

    function loaded(image) {
        if (image.status === Image.Ready && image.source == source)
            showFront = image === front;
    }

    Image {
        id: back
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        // Decode at screen size rather than the full image: two of these per
        // screen at 3200x1800 otherwise sit in memory for no visible gain.
        sourceSize.width: root.width
        sourceSize.height: root.height
        asynchronous: true
        // The same path can hold a different file (the active symlink gets
        // repointed).
        cache: false
        onStatusChanged: root.loaded(back)
    }

    Image {
        id: front
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.width
        sourceSize.height: root.height
        asynchronous: true
        cache: false
        onStatusChanged: root.loaded(front)

        opacity: root.showFront ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutCubic
            }
        }
    }
}
