import QtQuick
import "../Theme"

// Replaces waybar's clock module; the full date shows on hover. Click opens
// the calendar card (../CalendarCard.qml) on this bar's screen.
Pill {
    id: root
    property string screenName: ""
    readonly property bool cardOpen: UiState.calendarCardScreen === screenName
    bg: cardOpen ? Colors.red : Colors.mauve
    fg: Colors.mantle
    icon: cardOpen ? "close" : "schedule"
    value: Qt.formatDateTime(now, "HH:mm")
    label: Qt.formatDateTime(now, "ddd, d MMM yyyy")

    property date now: new Date()

    onClicked: {
        const open = cardOpen;
        UiState.closePanels();
        UiState.calendarCardScreen = open ? "" : screenName;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
