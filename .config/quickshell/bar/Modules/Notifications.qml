import "../Theme"
import "../Services"

// Opens the notification center (../NotificationCenter.qml) on this bar's
// screen; right click toggles do-not-disturb. Shows the unread count, and
// goes quiet (base/overlay, like the idle inhibitor when off) under DND.
Pill {
    id: root
    property string screenName: ""
    readonly property bool centerOpen: UiState.notifCenterScreen === screenName
    readonly property int unread: Math.min(Notifs.unread, Notifs.history.length)

    bg: centerOpen ? Colors.red : Notifs.dnd ? Colors.base : Colors.lavender
    fg: Notifs.dnd && !centerOpen ? Colors.overlay0 : Colors.mantle
    icon: centerOpen ? "close" : Notifs.dnd ? "notifications_off" : unread > 0 ? "notifications_unread" : "notifications"
    value: unread > 0 && !centerOpen ? String(unread) : ""
    label: Notifs.dnd ? "DND" : ""

    onClicked: {
        UiState.powerMenuScreen = "";
        UiState.notifCenterScreen = centerOpen ? "" : screenName;
    }
    onRightClicked: Notifs.dnd = !Notifs.dnd
}
