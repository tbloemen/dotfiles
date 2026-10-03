import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "Theme"
import "Services"

// Audio card, unfolding out of the bar's volume pill (on Card.qml): the
// default output and input with volume and mute, the devices to switch
// between, and per-app volume for whatever is playing. Covers what
// pavucontrol was opened for.
Card {
    id: root

    screenProp: "audioCardScreen"
    namespace: "audiocard"
    cardWidth: 340

    DeviceSection {
        title: "Output"
        node: Pipewire.defaultAudioSink
        devices: Audio.sinks
        accent: Colors.yellow
        icon: muted => muted ? "volume_off" : "volume_up"
        onPicked: n => Pipewire.preferredDefaultAudioSink = n
    }

    DeviceSection {
        title: "Input"
        node: Pipewire.defaultAudioSource
        devices: Audio.sources
        accent: Colors.mauve
        icon: muted => muted ? "mic_off" : "mic"
        onPicked: n => Pipewire.preferredDefaultAudioSource = n
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: Audio.streams.length > 0
        spacing: 2

        SectionTitle {
            text: "Apps"
        }

        Repeater {
            model: Audio.streams

            Rectangle {
                id: stream
                required property var modelData
                readonly property bool ready: modelData.audio !== null && modelData.ready
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 8
                color: Colors.base

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 10

                    Item {
                        implicitWidth: 24
                        implicitHeight: 24

                        Image {
                            id: appIcon
                            anchors.fill: parent
                            source: Audio.streamIcon(stream.modelData)
                            sourceSize.width: 48
                            sourceSize.height: 48
                            asynchronous: true
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: appIcon.status !== Image.Ready
                            text: "graphic_eq"
                            font.family: Metrics.iconFont
                            font.pixelSize: 20
                            color: Colors.subtext0
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: Audio.label(stream.modelData)
                                font.family: Metrics.uiFont
                                font.pixelSize: 11
                                font.bold: true
                                color: Colors.text
                            }

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: Audio.streamDetail(stream.modelData)
                                font.family: Metrics.uiFont
                                font.pixelSize: 10
                                color: Colors.overlay0
                            }
                        }

                        Slider {
                            Layout.fillWidth: true
                            enabled: stream.ready && !stream.modelData.audio.muted
                            accent: Colors.yellow
                            value: stream.ready ? stream.modelData.audio.volume : 0
                            onMoved: v => stream.modelData.audio.volume = v
                        }
                    }

                    MuteButton {
                        muted: stream.ready && stream.modelData.audio.muted
                        icon: muted ? "volume_off" : "volume_up"
                        accent: Colors.yellow
                        onClicked: stream.modelData.audio.muted = !stream.modelData.audio.muted
                    }
                }
            }
        }
    }

    // Default device with volume + mute, and the devices to switch to.
    component DeviceSection: ColumnLayout {
        id: section
        property string title
        property var node
        property var devices: []
        property color accent
        property var icon // muted => glyph
        signal picked(var node)

        readonly property bool ready: node !== null && node.audio !== null && node.ready
        readonly property bool muted: ready && node.audio.muted

        Layout.fillWidth: true
        spacing: 2

        SectionTitle {
            text: section.title
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            radius: 8
            color: Colors.base

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: section.node !== null ? Audio.label(section.node) : "No device"
                            font.family: Metrics.uiFont
                            font.pixelSize: 11
                            font.bold: true
                            color: Colors.text
                        }

                        Text {
                            text: section.ready ? Math.round(section.node.audio.volume * 100) + "%" : ""
                            font.family: Metrics.uiFont
                            font.pixelSize: 10
                            color: Colors.overlay0
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        enabled: section.ready && !section.muted
                        accent: section.accent
                        value: section.ready ? section.node.audio.volume : 0
                        onMoved: v => section.node.audio.volume = v
                    }
                }

                MuteButton {
                    muted: section.muted
                    icon: section.icon(section.muted)
                    accent: section.accent
                    enabled: section.ready
                    onClicked: section.node.audio.muted = !section.node.audio.muted
                }
            }
        }

        // Other devices; only worth listing when there's a choice.
        Repeater {
            model: section.devices.length > 1 ? section.devices : []

            Rectangle {
                id: device
                required property var modelData
                readonly property bool current: modelData === section.node
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 6
                color: deviceArea.containsMouse && !current ? Colors.base : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: device.current ? "radio_button_checked" : "radio_button_unchecked"
                        font.family: Metrics.iconFont
                        font.pixelSize: 14
                        color: device.current ? section.accent : Colors.overlay0
                    }

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: Audio.label(device.modelData)
                        font.family: Metrics.uiFont
                        font.pixelSize: 11
                        color: device.current ? Colors.text : Colors.subtext0
                    }
                }

                MouseArea {
                    id: deviceArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: device.current ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: if (!device.current)
                        section.picked(device.modelData)
                }
            }
        }
    }

    component SectionTitle: Text {
        Layout.leftMargin: 4
        Layout.topMargin: 2
        font.family: Metrics.uiFont
        font.pixelSize: 11
        font.bold: true
        color: Colors.overlay0
    }

    component MuteButton: Rectangle {
        id: mute
        property bool muted
        property string icon
        property color accent
        signal clicked

        implicitWidth: 30
        implicitHeight: 30
        radius: 15
        opacity: enabled ? 1 : 0.4
        color: muted ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.2) : muteArea.containsMouse ? Colors.surface0 : "transparent"

        Text {
            anchors.centerIn: parent
            text: mute.icon
            font.family: Metrics.iconFont
            font.pixelSize: 18
            color: mute.muted ? Colors.red : mute.accent
        }

        MouseArea {
            id: muteArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (mute.enabled)
                mute.clicked()
        }
    }
}
