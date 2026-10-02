import "../Theme"

// The actual Wayland.IdleInhibitor is instantiated in shell.qml (it needs a
// `window` reference to the PanelWindow); this is just the toggle button,
// bound to the shared Theme/UiState.qml singleton so all monitors agree.
Pill {
    id: root
    bg: UiState.idleInhibited ? Colors.green : Colors.base
    fg: UiState.idleInhibited ? Colors.mantle : Colors.overlay0
    icon: UiState.idleInhibited ? "coffee" : "nights_stay"
    label: UiState.idleInhibited ? "Caffeinated — staying awake" : "Decaffeinated — normal idle"

    onClicked: UiState.idleInhibited = !UiState.idleInhibited
}
