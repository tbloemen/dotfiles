import "../Theme"
import "../Services"

// Todoist pill: how many tasks are due today or overdue (red with any
// overdue). Click opens the Todoist card (../TodoistCard.qml) on this bar's
// screen; right click refreshes. Hidden until there's a token in the
// keyring.
Pill {
    id: root
    property string screenName: ""
    readonly property bool cardOpen: UiState.todoistCardScreen === screenName

    visible: Todoist.error !== "no-token"
    bg: cardOpen || Todoist.overdueCount > 0 ? Colors.red : Colors.green
    fg: Colors.mantle

    icon: cardOpen ? "close" : Todoist.count === 0 ? "task_alt" : "checklist"
    value: Todoist.count > 0 ? String(Todoist.count) : ""
    label: Todoist.overdueCount > 0 ? Todoist.overdueCount + " overdue" : Todoist.count === 0 ? "All done" : "today"

    onClicked: {
        const open = cardOpen;
        UiState.closePanels();
        UiState.todoistCardScreen = open ? "" : screenName;
    }
    onRightClicked: Todoist.refresh()
}
