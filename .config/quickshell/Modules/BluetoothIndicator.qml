import "../Theme"
import "../Services"

// Bluetooth pill, hidden without an adapter. Click opens the Bluetooth card
// (../BluetoothCard.qml) on this bar's screen; right click turns the
// adapter on/off. Hover shows what's connected.
Pill {
    id: root
    property string screenName: ""
    readonly property bool cardOpen: UiState.bluetoothCardScreen === screenName

    visible: Bt.adapter !== null
    bg: cardOpen ? Colors.red : Colors.lavender
    fg: Colors.mantle

    icon: cardOpen ? "close" : !Bt.enabled ? "bluetooth_disabled" : Bt.connected.length > 0 ? "bluetooth_connected" : "bluetooth"
    label: !Bt.enabled ? "Off" : Bt.connected.length > 0 ? Bt.connected.map(d => d.name).join(", ") : "On"

    onClicked: {
        const open = cardOpen;
        UiState.closePanels();
        UiState.bluetoothCardScreen = open ? "" : screenName;
    }
    onRightClicked: {
        if (Bt.adapter !== null)
            Bt.adapter.enabled = !Bt.adapter.enabled;
    }
}
