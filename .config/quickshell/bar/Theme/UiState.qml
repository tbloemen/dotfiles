pragma Singleton
import Quickshell

// Tiny shared UI state that needs to stay in sync across monitors (Variants
// instantiates one PanelWindow + IdleInhibitor per screen; the idle-inhibit
// toggle is a single global concept, not a per-monitor one).
Singleton {
    property bool idleInhibited: false

    // Name of the screen whose power menu is open, "" when closed. A screen
    // name rather than a bool so only the monitor you clicked on shows it.
    property string powerMenuScreen: ""

    // Same idea for the notification center (NotificationCenter.qml) and the
    // network card (NetworkCard.qml).
    property string notifCenterScreen: ""
    property string networkCardScreen: ""

    // Only one of the cards is open at a time: whoever opens one calls this
    // first.
    function closePanels() {
        powerMenuScreen = "";
        notifCenterScreen = "";
        networkCardScreen = "";
    }
}
