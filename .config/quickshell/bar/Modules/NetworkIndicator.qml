import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../Theme"

// Replaces waybar's network module. Click actions are intentionally kept as
// the existing rofi scripts (deliberately deferred scope, see migration
// plan) rather than a native quickshell network popup.
//
// Signal-strength bars from the old format-icons ramp are dropped: Quickshell
// v0.3.1's WifiNetwork only exposes signalStrength on discovered networks,
// not a documented direct link from WifiDevice to its currently-active
// network, so this shows connected/disconnected + wifi-vs-wired only.
Pill {
    id: root
    bg: Colors.teal
    fg: Colors.mantle

    // Empirically confirmed against this machine's NetworkManager devices:
    // Networking.devices[].type is 1 for Wifi, 2 for Wired.
    readonly property var connectedDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++) if (devices[i].connected) return devices[i];
        return null;
    }

    icon: connectedDevice === null ? "wifi_off"
        : connectedDevice.type === 2 ? "lan"
        : "wifi"

    label: connectedDevice === null ? "Disconnected"
        : connectedDevice.type === 2 ? "Wired — " + connectedDevice.name
        : "Wi-Fi — " + connectedDevice.name

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
