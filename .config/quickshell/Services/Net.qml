pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
import "../Theme"

// What the network pill and the network card (../NetworkCard.qml) both need
// to know about the current connection, on top of Quickshell.Networking.
//
// The SSID of the active Wi-Fi network has no direct link from its device:
// it's the entry in the device's discovered `networks` with `connected` set.
Singleton {
    id: root

    readonly property var connectedDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++)
            if (devices[i].connected)
                return devices[i];
        return null;
    }

    readonly property bool wired: connectedDevice !== null && connectedDevice.type === DeviceType.Wired

    readonly property var activeNetwork: {
        if (connectedDevice === null || wired)
            return null;
        const networks = connectedDevice.networks.values;
        for (let i = 0; i < networks.length; i++)
            if (networks[i].connected)
                return networks[i];
        return null;
    }

    // The Wi-Fi device whose networks the card lists, connected or not.
    readonly property var wifiDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wifi)
                return devices[i];
        return null;
    }

    // Scan only while a network card is open, so the list stays fresh there
    // without NetworkManager scanning in the background all the time. Lives
    // here rather than in the per-screen cards so they can't fight over it.
    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: UiState.networkCardScreen !== ""
        when: root.wifiDevice !== null
    }

    // signalStrength (0-1) to the same five-step bars ramp waybar used.
    function glyphFor(strength: real): string {
        return strength >= 0.8 ? "signal_wifi_4_bar" : strength >= 0.6 ? "network_wifi_3_bar" : strength >= 0.4 ? "network_wifi_2_bar" : strength >= 0.2 ? "network_wifi_1_bar" : "signal_wifi_0_bar";
    }

    function secured(network: var): bool {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }
}
