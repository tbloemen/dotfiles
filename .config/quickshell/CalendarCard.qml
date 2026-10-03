import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "Theme"
import "Services"

// Calendar card, unfolding out of the clock pill (on Card.qml): a month grid
// (Monday first) with a dot per calendar that has something that day, and
// below it the next two weeks of events -- or, after clicking a day, just
// that day's.
//
// Events come from Thunderbird's calendar cache via
// scripts/thunderbird-events.py, so they're as fresh as Thunderbird's last
// sync. It runs when the card opens and when the month changes.
//
// Todoist tasks due today or overdue (Services/Todoist.qml) show between
// the grid and the list, while it lists upcoming days or today.
Card {
    id: root

    screenProp: "calendarCardScreen"
    namespace: "calendarcard"
    align: "center"
    cardWidth: 320

    readonly property int upcomingDays: 14

    property date today: new Date()
    property date viewMonth: firstOfMonth(today)
    property var selectedDay: null // a Date, or null for "upcoming"
    property var events: []
    property bool loading: false

    // "YYYY-MM-DD" -> [event], an event listed on every day it covers.
    readonly property var byDay: {
        const map = {};
        for (const e of events) {
            const start = parseDate(e.start);
            const end = parseDate(e.end);
            // All-day ends are exclusive dates; a timed event ending at
            // midnight doesn't reach into the next day either.
            const last = new Date(Math.max(start.getTime(), end.getTime() - 1));
            for (let d = dayStart(start); d <= last; d = addDays(d, 1)) {
                const key = dayKey(d);
                (map[key] = map[key] ?? []).push(e);
            }
        }
        return map;
    }

    // First grid cell: the Monday on or before the 1st.
    readonly property date gridStart: addDays(viewMonth, -((viewMonth.getDay() + 6) % 7))

    readonly property int maxTasks: 5
    readonly property bool showTasks: Todoist.count > 0 && (selectedDay === null || sameDay(selectedDay, today))

    onOpened: {
        Todoist.refresh();
        today = new Date();
        selectedDay = null;
        if (viewMonth.getTime() === firstOfMonth(today).getTime())
            load();
        else
            viewMonth = firstOfMonth(today);
    }
    onViewMonthChanged: {
        if (open)
            load();
    }

    function firstOfMonth(d: date): date {
        return new Date(d.getFullYear(), d.getMonth(), 1);
    }
    function dayStart(d: date): date {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate());
    }
    function addDays(d: date, n: int): date {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
    }
    function dayKey(d: date): string {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
    }
    function sameDay(a, b): bool {
        return a !== null && b !== null && dayKey(a) === dayKey(b);
    }
    // Dates without a time are local days; JS would read them as UTC.
    function parseDate(s: string): date {
        if (s.length === 10) {
            const [y, m, d] = s.split("-").map(Number);
            return new Date(y, m - 1, d);
        }
        return new Date(s);
    }

    // Cover the visible grid and the upcoming list in one run.
    function load() {
        const first = new Date(Math.min(gridStart.getTime(), dayStart(today).getTime()));
        const last = new Date(Math.max(addDays(gridStart, 41).getTime(), addDays(today, upcomingDays).getTime()));
        loading = true;
        eventsProc.command = [Quickshell.shellPath("scripts/thunderbird-events.py"), "--from", dayKey(first), "--to", dayKey(last)];
        eventsProc.running = true;
    }

    Process {
        id: eventsProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.events = JSON.parse(text);
                } catch (e) {
                    root.events = [];
                }
                root.loading = false;
            }
        }
    }

    // What the list shows: [{day, events}], one entry per day with events.
    readonly property var listDays: {
        const days = selectedDay !== null ? [dayStart(selectedDay)] : Array.from({
            length: upcomingDays
        }, (_, i) => addDays(today, i));
        return days.map(d => ({
                    day: d,
                    events: byDay[dayKey(d)] ?? []
                })).filter(g => g.events.length > 0 || selectedDay !== null);
    }

    function dayTitle(d: date): string {
        if (sameDay(d, today))
            return "Today";
        if (sameDay(d, addDays(today, 1)))
            return "Tomorrow";
        return Qt.formatDate(d, "dddd d MMMM");
    }

    function timeText(e, day: date): string {
        if (e.allDay)
            return "All day";
        const start = parseDate(e.start);
        const end = parseDate(e.end);
        // Continuing from an earlier day, or running on past this one.
        const from = sameDay(start, day) ? Qt.formatTime(start, "HH:mm") : "…";
        const to = sameDay(end, day) || end.getTime() === addDays(day, 1).getTime() ? Qt.formatTime(end, "HH:mm") : "…";
        return start.getTime() === end.getTime() ? from : from + "–" + to;
    }

    // Header: month, navigation, open Thunderbird.
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(root.viewMonth, "MMMM yyyy")
            font.family: Metrics.uiFont
            font.pixelSize: 13
            font.bold: true
            color: Colors.text
        }

        HeaderButton {
            icon: "chevron_left"
            accent: Colors.subtext0
            onClicked: root.viewMonth = new Date(root.viewMonth.getFullYear(), root.viewMonth.getMonth() - 1, 1)
        }
        HeaderButton {
            label: "Today"
            accent: Colors.mauve
            onClicked: {
                root.selectedDay = null;
                root.viewMonth = root.firstOfMonth(root.today);
            }
        }
        HeaderButton {
            icon: "chevron_right"
            accent: Colors.subtext0
            onClicked: root.viewMonth = new Date(root.viewMonth.getFullYear(), root.viewMonth.getMonth() + 1, 1)
        }
        HeaderButton {
            icon: "open_in_new"
            accent: Colors.subtext0
            onClicked: {
                Quickshell.execDetached(["thunderbird"]);
                root.close();
            }
        }
    }

    // Month grid.
    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            Text {
                required property string modelData
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.family: Metrics.uiFont
                font.pixelSize: 10
                font.bold: true
                color: Colors.overlay0
            }
        }

        Repeater {
            model: 42

            Item {
                id: cell
                required property int index
                readonly property date day: root.addDays(root.gridStart, index)
                readonly property bool inMonth: day.getMonth() === root.viewMonth.getMonth()
                readonly property bool isToday: root.sameDay(day, root.today)
                readonly property bool isSelected: root.sameDay(day, root.selectedDay)
                // One dot per calendar with events that day, at most three.
                readonly property var colors: [...new Set((root.byDay[root.dayKey(day)] ?? []).map(e => e.color))].slice(0, 3)

                Layout.fillWidth: true
                implicitHeight: 38

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 3
                    width: 26
                    height: 26
                    radius: 13
                    color: cell.isToday ? Colors.mauve : cellArea.containsMouse ? Colors.surface0 : "transparent"
                    border.width: cell.isSelected && !cell.isToday ? 1 : 0
                    border.color: Colors.mauve

                    Text {
                        anchors.centerIn: parent
                        text: cell.day.getDate()
                        font.family: Metrics.uiFont
                        font.pixelSize: 12
                        font.bold: cell.isToday
                        color: cell.isToday ? Colors.mantle : cell.inMonth ? Colors.text : Colors.overlay0
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    spacing: 2

                    Repeater {
                        model: cell.colors

                        Rectangle {
                            required property string modelData
                            width: 4
                            height: 4
                            radius: 2
                            color: modelData
                            opacity: cell.inMonth ? 1 : 0.5
                        }
                    }
                }

                MouseArea {
                    id: cellArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // Click a day to list it; click it again for upcoming.
                    onClicked: root.selectedDay = cell.isSelected ? null : cell.day
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Colors.surface1
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        visible: root.showTasks

        Text {
            Layout.fillWidth: true
            text: "Tasks"
            font.family: Metrics.uiFont
            font.pixelSize: 11
            font.bold: true
            color: Colors.overlay0
        }

        HeaderButton {
            visible: Todoist.count > root.maxTasks
            label: "+" + (Todoist.count - root.maxTasks) + " more"
            accent: Colors.green
            onClicked: {
                const name = root.modelData.name;
                UiState.closePanels();
                UiState.todoistCardScreen = name;
            }
        }
    }

    Repeater {
        model: root.showTasks ? Todoist.tasks.slice(0, root.maxTasks) : []

        TodoistTask {
            required property var modelData
            Layout.fillWidth: true
            task: modelData
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4

        Text {
            Layout.fillWidth: true
            text: root.selectedDay !== null ? root.dayTitle(root.selectedDay) : "Upcoming"
            font.family: Metrics.uiFont
            font.pixelSize: 11
            font.bold: true
            color: Colors.overlay0
        }

        HeaderButton {
            visible: root.selectedDay !== null
            icon: "close"
            accent: Colors.subtext0
            onClicked: root.selectedDay = null
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: root.listDays.length === 0 ? 40 : Math.min(list.implicitHeight, 320)

        Text {
            anchors.centerIn: parent
            visible: root.listDays.length === 0
            text: root.loading ? "Loading…" : "Nothing in the next two weeks"
            font.family: Metrics.uiFont
            font.pixelSize: 12
            color: Colors.overlay0
        }

        Flickable {
            id: flick
            anchors.fill: parent
            contentWidth: width
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: list
                width: flick.width
                spacing: 6

                Repeater {
                    model: root.listDays

                    ColumnLayout {
                        id: group
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            visible: root.selectedDay === null
                            Layout.leftMargin: 4
                            text: root.dayTitle(group.modelData.day)
                            font.family: Metrics.uiFont
                            font.pixelSize: 11
                            font.bold: true
                            color: root.sameDay(group.modelData.day, root.today) ? Colors.mauve : Colors.subtext0
                        }

                        Text {
                            visible: group.modelData.events.length === 0
                            Layout.leftMargin: 4
                            text: "Nothing planned"
                            font.family: Metrics.uiFont
                            font.pixelSize: 11
                            color: Colors.overlay0
                        }

                        Repeater {
                            model: group.modelData.events

                            Rectangle {
                                id: event
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: eventCol.implicitHeight + 10
                                radius: 6
                                color: Colors.base

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 5
                                    width: 3
                                    radius: 1.5
                                    color: event.modelData.color
                                }

                                ColumnLayout {
                                    id: eventCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 8
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: event.modelData.title
                                        font.family: Metrics.uiFont
                                        font.pixelSize: 12
                                        color: Colors.text
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: root.timeText(event.modelData, group.modelData.day) + " · " + event.modelData.calendar
                                        font.family: Metrics.uiFont
                                        font.pixelSize: 10
                                        color: Colors.overlay0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
