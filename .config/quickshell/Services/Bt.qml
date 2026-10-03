pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../Theme"

// What the Bluetooth pill and card (../BluetoothCard.qml) both need, on top
// of Quickshell.Bluetooth (BlueZ). Pairing PIN/passkey prompts still go
// through blueman-applet, which is the registered BlueZ agent.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter // qmllint disable unresolved-type
    readonly property bool enabled: adapter !== null && adapter.enabled

    // Connected first, then paired, then nearby devices that report a name
    // (nameless ones only show their address, which is no help).
    readonly property var devices: {
        if (adapter === null)
            return [];
        return adapter.devices.values.filter(d => d.paired || d.connected || (d.deviceName && d.deviceName.length > 0)).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name));
    }

    readonly property var connected: devices.filter(d => d.connected)

    // Discover only while a card is open, like Net.qml's Wi-Fi scanning.
    Binding {
        target: root.adapter
        property: "discovering"
        value: UiState.bluetoothCardScreen !== ""
        when: root.adapter !== null && root.adapter.enabled
    }

    // BlueZ's freedesktop icon name to a Material Symbol.
    function glyphFor(device: var): string {
        const icon = device?.icon ?? "";
        if (icon.startsWith("audio-headset"))
            return "headset_mic";
        if (icon.startsWith("audio-headphones"))
            return "headphones";
        if (icon.startsWith("audio"))
            return "speaker";
        if (icon === "input-mouse")
            return "mouse";
        if (icon === "input-keyboard")
            return "keyboard";
        if (icon === "input-gaming")
            return "sports_esports";
        if (icon.startsWith("phone"))
            return "smartphone";
        if (icon === "computer")
            return "computer";
        return "bluetooth";
    }
}
