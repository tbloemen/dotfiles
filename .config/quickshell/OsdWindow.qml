import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "Theme"
import "Services"
import "Modules"

// Volume/brightness OSD: a pill near the bottom of the focused screen,
// driven entirely by the Osd singleton (Services/Osd.qml). One per screen;
// never takes input. For Osd.kind "track" the same pill shows cover art and
// the new track instead of a level bar.
PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property var modelData
    screen: modelData

    readonly property bool wanted: Osd.shown && Osd.screen === modelData.name
    property real progress: wanted ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: Metrics.animMedium
            easing.type: Easing.OutCubic
        }
    }

    visible: wanted || progress > 0
    color: "transparent"
    anchors.bottom: true
    margins.bottom: 80 // qmllint disable unqualified unresolved-type
    implicitWidth: pill.width + 24
    implicitHeight: pill.height + 24
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    Item {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: 12 + Math.round(12 * (1 - root.progress))
        opacity: root.progress
        readonly property bool track: Osd.kind === "track"
        width: track ? 340 : 260
        height: track ? 64 : 44

        // Shadow on a separate background so the level bar animating on top
        // doesn't force the blur to re-render every frame.
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Colors.base
            border.width: 1
            border.color: Colors.surface1
            layer.enabled: true
            layer.effect: PillShadow {}
        }

        readonly property color accent: Osd.muted ? Colors.overlay0 : Osd.icon.startsWith("brightness") ? Colors.yellow : Colors.mauve

        Text {
            id: icon
            visible: !pill.track
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: Osd.icon
            font.family: Metrics.iconFont
            font.pixelSize: 20
            color: pill.accent
        }

        Rectangle {
            id: track
            visible: !pill.track
            anchors.left: icon.right
            anchors.right: value.left
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: Colors.surface0

            Rectangle {
                width: parent.width * Osd.value
                height: parent.height
                radius: parent.radius
                color: pill.accent
                Behavior on width {
                    NumberAnimation {
                        duration: Metrics.animFast
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Text {
            id: value
            visible: !pill.track
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            horizontalAlignment: Text.AlignRight
            text: Math.round(Osd.value * 100)
            font.family: Metrics.uiFont
            font.pixelSize: Metrics.textSize
            color: Colors.text
        }
    
        Row {
            visible: pill.track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            ClippingRectangle {
                width: 44
                height: 44
                radius: 22
                color: Colors.surface0

                Image {
                    id: trackArt
                    anchors.fill: parent
                    source: Osd.art
                    sourceSize.width: 88
                    sourceSize.height: 88
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: trackArt.status !== Image.Ready
                    text: "music_note"
                    font.family: Metrics.iconFont
                    font.pixelSize: 20
                    color: Colors.flamingo
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 56
                spacing: 2

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: Osd.title
                    font.family: Metrics.uiFont
                    font.pixelSize: Metrics.textSize
                    font.bold: true
                    color: Colors.text
                }

                Text {
                    width: parent.width
                    visible: text.length > 0
                    elide: Text.ElideRight
                    text: Osd.subtitle
                    font.family: Metrics.uiFont
                    font.pixelSize: 11
                    color: Colors.subtext0
                }
            }
        }
}
}
