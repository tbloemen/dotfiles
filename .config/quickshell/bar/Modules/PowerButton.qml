import "../Theme"

// Replaces waybar's custom/power module. Opens the quickshell power menu
// (../PowerMenu.qml) on this bar's screen. While it's open the pill turns
// red with a close glyph, since clicking it again dismisses the menu.
Pill {
    id: root
    property string screenName: ""
    readonly property bool menuOpen: UiState.powerMenuScreen === screenName

    bg: menuOpen ? Colors.red : Colors.flamingo
    fg: Colors.mantle
    icon: menuOpen ? "close" : "power_settings_new"

    onClicked: {
        UiState.notifCenterScreen = "";
        UiState.powerMenuScreen = menuOpen ? "" : screenName;
    }
}
