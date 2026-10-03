import QtQuick
import QtQuick.Layouts
import Quickshell
import "Theme"
import "Services"

// Display card (on Card.qml), opened with SUPER+P: one-click layouts --
// extend, laptop only, external only, mirror -- and per monitor an on/off
// switch and its resolution/refresh modes. No pill, so it drops in centered
// under the bar. State and the hyprctl calls live in Services/Displays.qml.
Card {
    id: root

    screenProp: "displayCardScreen"
    namespace: "displaycard"
    align: "center"
    cardWidth: 360

    // The monitor whose mode list is unfolded.
    property string expanded: ""

    onOpened: {
        expanded = "";
        Displays.refresh();
    }

    Text {
        Layout.leftMargin: 4
        text: "Displays"
        font.family: Metrics.uiFont
        font.pixelSize: 12
        font.bold: true
        color: Colors.text
    }

    // Layout presets.
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 6
        visible: Displays.monitors.length > 1

        Repeater {
            model: [
                {
                    id: "extend",
                    icon: "desktop_windows",
                    label: "Extend"
                },
                {
                    id: "laptop",
                    icon: "laptop",
                    label: "Laptop"
                },
                {
                    id: "external",
                    icon: "monitor",
                    label: "External"
                },
                {
                    id: "mirror",
                    icon: "screen_share",
                    label: "Mirror"
                }
            ]

            Rectangle {
                id: preset
                required property var modelData
                readonly property bool current: Displays.layout === modelData.id
                Layout.fillWidth: true
                implicitHeight: 62
                radius: 8
                color: current ? Colors.teal : presetArea.containsMouse ? Colors.surface0 : Colors.base
                Behavior on color {
                    ColorAnimation {
                        duration: Metrics.animFast
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: preset.modelData.icon
                        font.family: Metrics.iconFont
                        font.pixelSize: 22
                        color: preset.current ? Colors.mantle : Colors.subtext0
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: preset.modelData.label
                        font.family: Metrics.uiFont
                        font.pixelSize: 11
                        font.bold: preset.current
                        color: preset.current ? Colors.mantle : Colors.text
                    }
                }

                MouseArea {
                    id: presetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Displays.setLayout(preset.modelData.id)
                }
            }
        }
    }

    // One block per monitor.
    Repeater {
        model: Displays.monitors

        Rectangle {
            id: monitor
            required property var modelData
            readonly property bool isExpanded: root.expanded === modelData.name
            readonly property string currentMode: modelData.width + "x" + modelData.height + "@" + Number(modelData.refreshRate).toFixed(2) + "Hz"
            // availableModes repeats some entries; keep the first of each.
            readonly property var modes: [...new Set(modelData.availableModes ?? [])]
            Layout.fillWidth: true
            implicitHeight: content.implicitHeight + 16
            radius: 8
            color: Colors.base

            ColumnLayout {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                anchors.leftMargin: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: Displays.isInternal(monitor.modelData) ? "laptop" : "monitor"
                        font.family: Metrics.iconFont
                        font.pixelSize: 20
                        color: monitor.modelData.disabled ? Colors.overlay0 : Colors.teal
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            // Laptop panels report codes like "0x2992" as their model.
                            text: Displays.isInternal(monitor.modelData) ? "Built-in display" : (monitor.modelData.model || monitor.modelData.description || monitor.modelData.name)
                            font.family: Metrics.uiFont
                            font.pixelSize: 12
                            font.bold: true
                            color: Colors.text
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: monitor.modelData.name + " · " + (monitor.modelData.disabled ? "off" : monitor.modelData.mirrorOf && monitor.modelData.mirrorOf !== "none" ? "mirroring " + monitor.modelData.mirrorOf : monitor.modelData.width + "×" + monitor.modelData.height + " @ " + Math.round(monitor.modelData.refreshRate) + " Hz")
                            font.family: Metrics.uiFont
                            font.pixelSize: 10
                            color: Colors.subtext0
                        }
                    }

                    HeaderButton {
                        visible: !monitor.modelData.disabled && monitor.modes.length > 1
                        icon: monitor.isExpanded ? "expand_less" : "tune"
                        accent: Colors.subtext0
                        onClicked: root.expanded = monitor.isExpanded ? "" : monitor.modelData.name
                    }

                    // On/off switch.
                    Rectangle {
                        id: toggle
                        readonly property bool on: !monitor.modelData.disabled
                        // The last screen that's on can't be turned off.
                        enabled: !on || Displays.enabledCount > 1
                        opacity: enabled ? 1 : 0.4
                        implicitWidth: 36
                        implicitHeight: 20
                        radius: 10
                        color: on ? Colors.teal : Colors.surface1

                        Rectangle {
                            x: toggle.on ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: toggle.on ? Colors.mantle : Colors.overlay0
                            Behavior on x {
                                NumberAnimation {
                                    duration: Metrics.animFast
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: toggle.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (toggle.enabled)
                                Displays.setEnabled(monitor.modelData, !toggle.on)
                        }
                    }
                }

                // Resolution / refresh modes.
                Flow {
                    Layout.fillWidth: true
                    visible: monitor.isExpanded
                    spacing: 4

                    Repeater {
                        model: monitor.isExpanded ? monitor.modes : []

                        Rectangle {
                            id: mode
                            required property string modelData
                            readonly property bool current: modelData === monitor.currentMode
                            width: modeText.implicitWidth + 16
                            height: 24
                            radius: 12
                            color: current ? Colors.teal : modeArea.containsMouse ? Colors.surface0 : Colors.mantle

                            Text {
                                id: modeText
                                anchors.centerIn: parent
                                text: mode.modelData.replace(/\.00Hz$/, "Hz").replace(/Hz$/, " Hz").replace("@", " @ ")
                                font.family: Metrics.uiFont
                                font.pixelSize: 10
                                color: mode.current ? Colors.mantle : Colors.subtext0
                            }

                            MouseArea {
                                id: modeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Displays.setMode(monitor.modelData, mode.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
