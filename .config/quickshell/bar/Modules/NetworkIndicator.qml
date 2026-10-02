import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../Theme"

// Replaces waybar's network module. Click actions are intentionally kept as
// the existing rofi scripts (deliberately deferred scope, see migration
// plan) rather than a native quickshell network popup.
//
// The Wi-Fi label shows the SSID of the active network: a device has no direct
// link to it, so it's the entry in the device's discovered `networks` with
// `connected` set (falls back to the interface name while that resolves).
// Its signalStrength (0-1) drives the same five-step bars ramp waybar used.
Pill {
    id: root
    bg: Colors.teal
    fg: Colors.mantle

    // Empirically confirmed against this machine's NetworkManager devices:
    // Networking.devices[].type is 1 for Wifi, 2 for Wired.
    readonly property var connectedDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++)
            if (devices[i].connected)
                return devices[i];
        return null;
    }

    readonly property var activeNetwork: {
        if (connectedDevice === null)
            return null;
        const networks = connectedDevice.networks.values;
        for (let i = 0; i < networks.length; i++)
            if (networks[i].connected)
                return networks[i];
        return null;
    }

    readonly property string wifiGlyph: {
        if (activeNetwork === null)
            return "wifi";
        const strength = activeNetwork.signalStrength;
        return strength >= 0.8 ? "signal_wifi_4_bar" : strength >= 0.6 ? "network_wifi_3_bar" : strength >= 0.4 ? "network_wifi_2_bar" : strength >= 0.2 ? "network_wifi_1_bar" : "signal_wifi_0_bar";
    }

    icon: connectedDevice === null ? "wifi_off" : connectedDevice.type === 2 ? "lan" : wifiGlyph

    label: connectedDevice === null ? "Disconnected" : connectedDevice.type === 2 ? "Wired — " + connectedDevice.name : (activeNetwork && activeNetwork.name || connectedDevice.name)

    onClicked: wifiProc.startDetached()
    onRightClicked: wifiNewProc.startDetached()

    Process {
        id: wifiProc
        command: [Quickshell.env("HOME") + "/.config/rofi/wifi/wifi.sh"]
    }
    Process {
        id: wifiNewProc
        command: [Quickshell.env("HOME") + "/.config/rofi/wifi/wifinew.sh"]
    }
}
