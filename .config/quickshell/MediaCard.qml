import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "Theme"
import "Services"

// Media card, unfolding out of the bar's now-playing pill (on Card.qml):
// cover art, track, a seek bar, transport controls, and a player switcher
// when more than one MPRIS player is around. Shows Media.active.
Card {
    id: root

    screenProp: "mediaCardScreen"
    namespace: "mediacard"
    align: "left"
    cardWidth: 340

    readonly property var player: Media.active

    // Header: which player, and a button to bring its window up.
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 4

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.player !== null ? root.player.identity : "Nothing playing"
            font.family: Metrics.uiFont
            font.pixelSize: 12
            font.bold: true
            color: Colors.text
        }

        HeaderButton {
            visible: root.player !== null && root.player.canRaise
            icon: "open_in_new"
            label: "Show"
            accent: Colors.subtext0
            onClicked: {
                root.player.raise();
                root.close();
            }
        }
    }

    // Art + track.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 112
        radius: 8
        color: Colors.base
        visible: root.player !== null

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12

            ClippingRectangle {
                implicitWidth: 96
                implicitHeight: 96
                radius: 6
                color: Colors.surface0

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize.width: 192
                    sourceSize.height: 192
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: "music_note"
                    font.family: Metrics.iconFont
                    font.pixelSize: 36
                    color: Colors.overlay0
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || "Unknown track"
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: Metrics.uiFont
                    font.pixelSize: 13
                    font.bold: true
                    color: Colors.text
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.player?.trackArtist ?? ""
                    elide: Text.ElideRight
                    font.family: Metrics.uiFont
                    font.pixelSize: 12
                    color: Colors.subtext0
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.player?.trackAlbum ?? ""
                    elide: Text.ElideRight
                    font.family: Metrics.uiFont
                    font.pixelSize: 11
                    color: Colors.overlay0
                }
            }
        }
    }

    // Seek bar with elapsed / total.
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 0
        visible: root.player !== null && root.player.lengthSupported && root.player.length > 0

        Slider {
            Layout.fillWidth: true
            enabled: root.player?.canSeek ?? false
            accent: Colors.flamingo
            value: root.player !== null && root.player.length > 0 ? root.player.position / root.player.length : 0
            onMoved: v => root.player.position = v * root.player.length
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: Media.formatTime(root.player?.position ?? 0)
                font.family: Metrics.uiFont
                font.pixelSize: 10
                color: Colors.overlay0
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: Media.formatTime(root.player?.length ?? 0)
                font.family: Metrics.uiFont
                font.pixelSize: 10
                color: Colors.overlay0
            }
        }
    }

    // Transport.
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        visible: root.player !== null
        spacing: 10

        ControlButton {
            visible: root.player?.shuffleSupported ?? false
            icon: "shuffle"
            active: root.player?.shuffle ?? false
            onClicked: root.player.shuffle = !root.player.shuffle
        }
        ControlButton {
            icon: "skip_previous"
            enabled: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }
        ControlButton {
            icon: root.player?.isPlaying ? "pause" : "play_arrow"
            primary: true
            enabled: root.player?.canTogglePlaying ?? false
            onClicked: root.player.togglePlaying()
        }
        ControlButton {
            icon: "skip_next"
            enabled: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
        ControlButton {
            visible: root.player?.loopSupported ?? false
            icon: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            active: root.player !== null && root.player.loopState !== MprisLoopState.None
            onClicked: {
                const s = root.player.loopState;
                root.player.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist : s === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
            }
        }
    }

    // Player switcher.
    Flow {
        Layout.fillWidth: true
        visible: Media.players.length > 1
        spacing: 4

        Repeater {
            model: Media.players

            Rectangle {
                id: chip
                required property var modelData
                readonly property bool current: modelData === root.player
                width: chipText.implicitWidth + 20
                height: 24
                radius: 12
                color: current ? Colors.flamingo : chipArea.containsMouse ? Colors.surface0 : Colors.base

                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: (chip.modelData.isPlaying ? "▶ " : "") + chip.modelData.identity
                    font.family: Metrics.uiFont
                    font.pixelSize: 11
                    color: chip.current ? Colors.mantle : Colors.subtext0
                }

                MouseArea {
                    id: chipArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.pinned = chip.modelData
                }
            }
        }
    }

    component ControlButton: Rectangle {
        id: ctl
        property string icon
        property bool primary: false
        property bool active: false
        signal clicked

        implicitWidth: primary ? 44 : 32
        implicitHeight: implicitWidth
        radius: width / 2
        opacity: enabled ? 1 : 0.4
        color: primary ? Colors.flamingo : ctlArea.containsMouse && enabled ? Colors.surface0 : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Metrics.animFast
            }
        }

        Text {
            anchors.centerIn: parent
            text: ctl.icon
            font.family: Metrics.iconFont
            font.pixelSize: ctl.primary ? 24 : 20
            color: ctl.primary ? Colors.mantle : ctl.active ? Colors.flamingo : Colors.subtext0
        }

        MouseArea {
            id: ctlArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: ctl.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (ctl.enabled)
                ctl.clicked()
        }
    }
}
