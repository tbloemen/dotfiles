import Quickshell.Networking
import "../Theme"
import "../Services"

// Replaces waybar's network module. Click opens the network card
// (../NetworkCard.qml) on this bar's screen; right click toggles the Wi-Fi
// radio. While the card is open the pill turns red with a close glyph, like
// the notification and power pills.
//
// The Wi-Fi label shows the SSID of the active network (falls back to the
// interface name while that resolves).
Pill {
    id: root
    property string screenName: ""
    readonly property bool cardOpen: UiState.networkCardScreen === screenName
    readonly property var device: Net.connectedDevice
    readonly property var network: Net.activeNetwork

    bg: cardOpen ? Colors.red : Colors.teal
    fg: Colors.mantle

    icon: cardOpen ? "close" : device === null ? (Networking.wifiEnabled ? "wifi_find" : "wifi_off") : Net.wired ? "lan" : network === null ? "wifi" : Net.glyphFor(network.signalStrength)

    label: device === null ? (Networking.wifiEnabled ? "Disconnected" : "Wi-Fi off") : Net.wired ? "Wired — " + device.name : (network && network.name || device.name)

    onClicked: {
        const open = cardOpen;
        UiState.closePanels();
        UiState.networkCardScreen = open ? "" : screenName;
    }
    onRightClicked: Networking.wifiEnabled = !Networking.wifiEnabled
}
