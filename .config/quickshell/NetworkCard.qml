pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Wayland
import "Theme"
import "Services"

// Network card, unfolding out of the bar's network pill. Same window/focus
// setup as NotificationCenter.qml (see PowerMenu.qml on why it's a
// HyprlandFocusGrab and not exclusive keyboard focus): one per screen, open
// when its name is in UiState.networkCardScreen, outside click or Esc closes.
//
// Shows the current connection and, while Wi-Fi is on, the networks the
// device can see (Net scans while any card is open). Click a network to
// connect: known and open ones connect straight away, a new secured one asks
// for its password inline. Click the connected one (or right click a known
// one) for disconnect / forget.
PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property var modelData
    required property PanelWindow barWindow
    property real anchorRight: Metrics.gap
    screen: modelData

    readonly property bool open: UiState.networkCardScreen === modelData.name
    property real progress: 0 // 0 closed .. 1 open
    readonly property int cardWidth: 320

    // The one row whose actions / password field are showing.
    property var expanded: null

    function close() {
        UiState.networkCardScreen = "";
    }

    onOpenChanged: {
        if (open) {
            closeAnim.stop();
            expanded = null;
            flick.contentY = 0;
            openAnim.restart();
        } else {
            openAnim.stop();
            closeAnim.restart();
        }
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "progress"
        to: 1
        duration: 340
        easing.type: Easing.OutExpo
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "progress"
        to: 0
        duration: 170
        easing.type: Easing.InCubic
    }

    visible: open || progress > 0
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:networkcard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        windows: [root, root.barWindow]
        active: root.open
        onCleared: root.close()
    }

    // Connected first, then saved networks, then by signal. ScriptModel diffs
    // by object, so a re-sort moves rows instead of recreating them (which
    // would eat a half-typed password).
    ScriptModel {
        id: networkModel
        values: {
            const device = Net.wifiDevice;
            if (device === null || !Networking.wifiEnabled)
                return [];
            return device.networks.values.filter(n => n.name.length > 0).sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.crust
        opacity: 0.25 * root.progress

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: root.close()
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            }
        }
    }

    Item {
        id: panel

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Metrics.gap - 10 * (1 - root.progress)
        // Line the card's right edge up with the pill's, but keep it on screen.
        anchors.rightMargin: Math.round(Math.max(Metrics.gap, Math.min(root.anchorRight, root.width - width - Metrics.gap)))
        width: root.cardWidth + 16
        height: header.height + status.height + body.height + 28

        transformOrigin: Item.TopRight
        scale: 0.9 + 0.1 * root.progress
        opacity: root.progress

        // The shadow sits on a background of its own: a layer on the whole
        // card would render the text into a texture and resample it, which
        // blurs it.
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Colors.mantle
            border.width: 1
            border.color: Colors.surface1
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, Colors.mode === "light" ? 0.18 : 0.45)
                shadowBlur: 0.9
                shadowVerticalOffset: 4
            }
        }

        // Keep clicks on the panel's own padding away from the scrim.
        MouseArea {
            anchors.fill: parent
        }

        RowLayout {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            anchors.leftMargin: 12
            height: 32
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: "Network"
                font.family: Metrics.uiFont
                font.pixelSize: 12
                font.bold: true
                color: Colors.text
            }

            HeaderButton {
                icon: Networking.wifiEnabled ? "wifi" : "wifi_off"
                label: Networking.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
                accent: Networking.wifiEnabled ? Colors.teal : Colors.overlay0
                enabled: Networking.wifiHardwareEnabled
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        // The current connection.
        Rectangle {
            id: status
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            anchors.topMargin: 4
            height: 56
            radius: 8
            color: Colors.base

            readonly property var device: Net.connectedDevice
            readonly property var network: Net.activeNetwork
            readonly property string warning: device === null ? "" : Networking.connectivity === NetworkConnectivity.Portal ? "Sign-in required" : Networking.connectivity === NetworkConnectivity.Limited ? "Limited connectivity" : Networking.connectivity === NetworkConnectivity.None ? "No internet" : ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 10

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 17
                    color: status.device === null ? Colors.surface0 : Colors.teal
                    Behavior on color {
                        ColorAnimation {
                            duration: Metrics.animMedium
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: status.device === null ? (Networking.wifiEnabled ? "wifi_find" : "wifi_off") : Net.wired ? "lan" : status.network === null ? "wifi" : Net.glyphFor(status.network.signalStrength)
                        font.family: Metrics.iconFont
                        font.pixelSize: 18
                        color: status.device === null ? Colors.subtext0 : Colors.mantle
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: status.device === null ? (Networking.wifiEnabled ? "Not connected" : "Wi-Fi is off") : Net.wired ? "Wired" : (status.network && status.network.name || status.device.name)
                        font.family: Metrics.uiFont
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.text
                    }

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: {
                            const d = status.device;
                            if (d === null)
                                return Networking.wifiHardwareEnabled ? "" : "Blocked by hardware switch";
                            if (Net.wired)
                                return d.name + (d.linkSpeed > 0 ? " · " + d.linkSpeed + " Mb/s" : "");
                            const n = status.network;
                            if (n === null)
                                return d.name;
                            return Math.round(n.signalStrength * 100) + "% · " + WifiSecurityType.toString(n.security) + " · " + d.name;
                        }
                        visible: text.length > 0
                        font.family: Metrics.uiFont
                        font.pixelSize: 11
                        color: Colors.subtext0
                    }

                    Text {
                        visible: status.warning.length > 0
                        text: status.warning
                        font.family: Metrics.uiFont
                        font.pixelSize: 11
                        color: Colors.peach
                    }
                }
            }
        }

        Item {
            id: body
            anchors.top: status.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            anchors.topMargin: 8
            // Grow with the list, up to most of the screen, then scroll.
            height: networkModel.values.length === 0 ? 56 : Math.min(list.implicitHeight, root.height * 0.6)

            Behavior on height {
                NumberAnimation {
                    duration: Metrics.animMedium
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                anchors.centerIn: parent
                visible: networkModel.values.length === 0
                text: !Networking.wifiEnabled ? "Turn on Wi-Fi to see networks" : Net.wifiDevice === null ? "No Wi-Fi device" : "Scanning…"
                font.family: Metrics.uiFont
                font.pixelSize: 12
                color: Colors.overlay0
            }

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: width
                contentHeight: list.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: list
                    width: flick.width
                    spacing: 2

                    Repeater {
                        model: networkModel

                        NetworkRow {
                            required property var modelData
                            network: modelData
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    component NetworkRow: Rectangle {
        id: row

        property var network
        readonly property bool isExpanded: root.expanded === network
        readonly property bool secured: Net.secured(network)
        // Set when a saved password turned out wrong, so a known network asks
        // for a new one too.
        property bool askPassword: false
        property string error: ""
        readonly property bool showPassword: isExpanded && (askPassword || (!network.known && secured))
        readonly property bool showActions: isExpanded && !showPassword

        function toggleExpanded() {
            root.expanded = isExpanded ? null : network;
        }

        function activate() {
            error = "";
            if (network.connected || (secured && (!network.known || askPassword))) {
                toggleExpanded();
            } else {
                root.expanded = null;
                network.connect();
            }
        }

        function submit() {
            if (password.text.length === 0)
                return;
            error = "";
            askPassword = false;
            network.connectWithPsk(password.text);
            password.text = "";
            root.expanded = null;
        }

        onShowPasswordChanged: {
            if (showPassword)
                password.forceActiveFocus();
        }

        Connections {
            target: row.network
            function onConnectionFailed(reason) {
                if (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout) {
                    row.error = "Wrong password";
                    row.askPassword = row.secured;
                    password.text = "";
                    root.expanded = row.network;
                } else {
                    row.error = ConnectionFailReason.toString(reason);
                }
            }
            function onConnectedChanged() {
                if (row.network.connected) {
                    row.error = "";
                    row.askPassword = false;
                }
            }
        }

        implicitHeight: content.implicitHeight + 12
        radius: 8
        color: network.connected ? Colors.surface0 : rowHover.hovered ? Colors.base : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Metrics.animFast
            }
        }

        HoverHandler {
            id: rowHover
        }

        // Declared before the content so it sits underneath: the buttons and
        // the password field take their own clicks first.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    if (row.network.known || row.network.connected)
                        row.toggleExpanded();
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
                    text: Net.glyphFor(row.network.signalStrength)
                    font.family: Metrics.iconFont
                    font.pixelSize: 16
                    color: row.network.connected ? Colors.teal : Colors.subtext0
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: row.network.name
                        font.family: Metrics.uiFont
                        font.pixelSize: 12
                        font.bold: row.network.connected
                        color: Colors.text
                    }

                    Text {
                        readonly property string stateText: row.error.length > 0 ? row.error : row.network.stateChanging ? (row.network.connected ? "Disconnecting…" : "Connecting…") : row.network.connected ? "Connected" : row.network.known ? "Saved" : ""
                        visible: stateText.length > 0
                        text: stateText
                        font.family: Metrics.uiFont
                        font.pixelSize: 10
                        color: row.error.length > 0 ? Colors.red : row.network.connected ? Colors.teal : Colors.subtext0
                    }
                }

                Text {
                    visible: row.network.stateChanging
                    text: "progress_activity"
                    font.family: Metrics.iconFont
                    font.pixelSize: 14
                    color: Colors.subtext0
                    RotationAnimation on rotation {
                        running: row.network.stateChanging
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }
                }

                Text {
                    visible: row.secured
                    text: "lock"
                    font.family: Metrics.iconFont
                    font.pixelSize: 13
                    color: Colors.overlay0
                }
            }

            // Password entry for a new (or wrongly saved) secured network.
            RowLayout {
                Layout.fillWidth: true
                visible: row.showPassword
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: 6
                    color: Colors.base
                    border.width: 1
                    border.color: password.activeFocus ? Colors.teal : Colors.surface1

                    TextInput {
                        id: password
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        echoMode: reveal.checked ? TextInput.Normal : TextInput.Password
                        font.family: Metrics.uiFont
                        font.pixelSize: 12
                        color: Colors.text
                        selectionColor: Colors.surface1
                        onAccepted: row.submit()
                        Keys.onEscapePressed: root.expanded = null

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: password.text.length === 0
                            text: "Password"
                            font: password.font
                            color: Colors.overlay0
                        }
                    }
                }

                HeaderButton {
                    id: reveal
                    property bool checked: false
                    icon: checked ? "visibility_off" : "visibility"
                    accent: Colors.subtext0
                    onClicked: checked = !checked
                }

                HeaderButton {
                    icon: "arrow_forward"
                    accent: Colors.teal
                    enabled: password.text.length > 0
                    onClicked: row.submit()
                }
            }

            // Actions for the connected or a saved network.
            RowLayout {
                Layout.fillWidth: true
                visible: row.showActions
                spacing: 4

                Item {
                    Layout.fillWidth: true
                }

                HeaderButton {
                    visible: !row.network.connected
                    icon: "link"
                    label: "Connect"
                    accent: Colors.teal
                    onClicked: {
                        root.expanded = null;
                        row.network.connect();
                    }
                }

                HeaderButton {
                    visible: row.network.connected
                    icon: "link_off"
                    label: "Disconnect"
                    accent: Colors.peach
                    onClicked: {
                        root.expanded = null;
                        row.network.disconnect();
                    }
                }

                HeaderButton {
                    visible: row.network.known
                    icon: "delete"
                    label: "Forget"
                    accent: Colors.red
                    onClicked: {
                        root.expanded = null;
                        row.network.forget();
                    }
                }
            }
        }
    }
}
