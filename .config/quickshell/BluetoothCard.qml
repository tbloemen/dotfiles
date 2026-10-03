pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "Theme"
import "Services"

// Bluetooth card, unfolding out of the bar's Bluetooth pill (on Card.qml).
// Lists connected, paired and nearby devices (the adapter discovers while
// the card is open, see Bt.qml). Click a paired device to connect or
// disconnect it, click a new one to pair (it's then trusted and connected);
// right click a paired one for disconnect / forget.
Card {
    id: root

    screenProp: "bluetoothCardScreen"
    namespace: "bluetoothcard"

    // The one row whose actions are showing.
    property var expanded: null

    onOpened: {
        expanded = null;
        flick.contentY = 0;
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 4

        Text {
            text: "Bluetooth"
            font.family: Metrics.uiFont
            font.pixelSize: 12
            font.bold: true
            color: Colors.text
        }

        Text {
            Layout.fillWidth: true
            visible: Bt.adapter?.discovering ?? false
            text: "searching…"
            font.family: Metrics.uiFont
            font.pixelSize: 11
            color: Colors.overlay0
        }

        Item {
            Layout.fillWidth: true
            visible: !(Bt.adapter?.discovering ?? false)
        }

        HeaderButton {
            icon: Bt.enabled ? "bluetooth" : "bluetooth_disabled"
            label: Bt.enabled ? "On" : "Off"
            accent: Bt.enabled ? Colors.lavender : Colors.overlay0
            enabled: Bt.adapter !== null && Bt.adapter.state !== BluetoothAdapterState.Blocked
            onClicked: Bt.adapter.enabled = !Bt.adapter.enabled
        }
    }

    Item {
        Layout.fillWidth: true
        // Grow with the list, up to most of the screen, then scroll.
        implicitHeight: !Bt.enabled || Bt.devices.length === 0 ? 56 : Math.min(list.implicitHeight, root.height * 0.6)

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Metrics.animMedium
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !Bt.enabled || Bt.devices.length === 0
            text: Bt.adapter === null ? "No Bluetooth adapter" : Bt.adapter.state === BluetoothAdapterState.Blocked ? "Blocked by rfkill" : !Bt.enabled ? "Turn on Bluetooth to see devices" : "Searching…"
            font.family: Metrics.uiFont
            font.pixelSize: 12
            color: Colors.overlay0
        }

        Flickable {
            id: flick
            anchors.fill: parent
            visible: Bt.enabled
            contentWidth: width
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: list
                width: flick.width
                spacing: 2

                Repeater {
                    model: ScriptModel {
                        values: Bt.devices
                    }

                    DeviceRow {
                        required property var modelData
                        device: modelData
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    component DeviceRow: Rectangle {
        id: row

        property var device
        readonly property bool isExpanded: root.expanded === device
        readonly property bool busy: device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting
        // A device paired from here gets trusted and connected once pairing
        // finishes.
        property bool connectAfterPair: false

        function activate() {
            root.expanded = null;
            if (busy)
                return;
            if (device.connected) {
                device.disconnect();
            } else if (device.paired) {
                device.connect();
            } else {
                connectAfterPair = true;
                device.pair();
            }
        }

        Connections {
            target: row.device
            function onPairedChanged() {
                if (row.device.paired && row.connectAfterPair) {
                    row.connectAfterPair = false;
                    row.device.trusted = true;
                    row.device.connect();
                }
            }
            function onPairingChanged() {
                // Pairing ended without success (rejected, timed out).
                if (!row.device.pairing && !row.device.paired)
                    row.connectAfterPair = false;
            }
        }

        implicitHeight: content.implicitHeight + 12
        radius: 8
        color: device.connected ? Colors.surface0 : rowHover.hovered ? Colors.base : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Metrics.animFast
            }
        }

        HoverHandler {
            id: rowHover
        }

        // Underneath the content so the action buttons get their own clicks.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    if (row.device.paired)
                        root.expanded = row.isExpanded ? null : row.device;
                } else {
                    row.activate();
                }
            }
        }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: Bt.glyphFor(row.device)
                    font.family: Metrics.iconFont
                    font.pixelSize: 18
                    color: row.device.connected ? Colors.lavender : Colors.subtext0
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: row.device.name
                        font.family: Metrics.uiFont
                        font.pixelSize: 12
                        font.bold: row.device.connected
                        color: Colors.text
                    }

                    Text {
                        readonly property string stateText: row.device.pairing ? "Pairing…" : row.device.state === BluetoothDeviceState.Connecting ? "Connecting…" : row.device.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…" : row.device.connected ? "Connected" + (row.device.batteryAvailable ? " · " + Math.round(row.device.battery * 100) + "%" : "") : row.device.paired ? "Paired" : ""
                        visible: stateText.length > 0
                        text: stateText
                        font.family: Metrics.uiFont
                        font.pixelSize: 10
                        color: row.device.connected ? Colors.lavender : Colors.subtext0
                    }
                }

                Text {
                    visible: row.busy
                    text: "progress_activity"
                    font.family: Metrics.iconFont
                    font.pixelSize: 14
                    color: Colors.subtext0
                    RotationAnimation on rotation {
                        running: row.busy
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }
                }
            }

            // Actions for a paired device.
            RowLayout {
                Layout.fillWidth: true
                visible: row.isExpanded
                spacing: 4

                Item {
                    Layout.fillWidth: true
                }

                HeaderButton {
                    visible: !row.device.connected
                    icon: "link"
                    label: "Connect"
                    accent: Colors.lavender
                    onClicked: {
                        root.expanded = null;
                        row.device.connect();
                    }
                }

                HeaderButton {
                    visible: row.device.connected
                    icon: "link_off"
                    label: "Disconnect"
                    accent: Colors.peach
                    onClicked: {
                        root.expanded = null;
                        row.device.disconnect();
                    }
                }

                HeaderButton {
                    icon: "delete"
                    label: "Forget"
                    accent: Colors.red
                    onClicked: {
                        root.expanded = null;
                        row.device.forget();
                    }
                }
            }
        }
    }
}
