import QtQuick
import QtQuick.Layouts
import "Theme"
import "Services"

// One Todoist task (an entry of Services/Todoist.qml's tasks), shared by
// TodoistCard.qml and CalendarCard.qml. Styled like the calendar's event
// rows. The ring completes the task, the rest of the row opens it in
// Todoist.
Rectangle {
    id: root

    required property var task
    property bool done: false

    implicitHeight: col.implicitHeight + 10
    radius: 6
    color: rowArea.containsMouse ? Colors.surface0 : Colors.base
    opacity: done ? 0.5 : 1

    // p1 red, p2 peach, p3 blue, p4 plain -- Todoist's own colors.
    readonly property color priorityColor: task.priority === 1 ? Colors.red : task.priority === 2 ? Colors.peach : task.priority === 3 ? Colors.lavender : Colors.overlay0

    function dueText(): string {
        const t = root.task;
        if (!t.due)
            return "";
        const today = new Date();
        // A bare date would parse as UTC midnight; with a time it's local.
        const d = new Date(t.time ? t.due : t.due + "T00:00:00");
        const isToday = d.toDateString() === today.toDateString();
        const time = t.time ? Qt.formatTime(d, "HH:mm") : "";
        const day = isToday ? (t.time ? "" : "Today") : Qt.formatDate(d, "ddd d MMM");
        const when = [day, time].filter(s => s !== "").join(" ");
        return t.overdue ? "Overdue · " + when : when;
    }

    Behavior on color {
        ColorAnimation {
            duration: Metrics.animFast
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: Metrics.animFast
        }
    }

    MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Todoist.openTask(root.task.id)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 5
        width: 3
        radius: 1.5
        color: root.task.projectColor
    }

    // The checkbox: fills and ticks, then the task leaves the list.
    Rectangle {
        id: check
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: root.done || checkArea.containsMouse ? Qt.alpha(root.priorityColor, root.done ? 1 : 0.25) : "transparent"
        border.width: 1.5
        border.color: root.priorityColor

        Text {
            anchors.centerIn: parent
            visible: root.done || checkArea.containsMouse
            text: "check"
            font.family: Metrics.iconFont
            font.pixelSize: 12
            font.bold: true
            color: root.done ? Colors.mantle : root.priorityColor
        }

        MouseArea {
            id: checkArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.done)
                    return;
                root.done = true;
                completeTimer.start();
            }
        }
    }

    // Long enough to see the tick before the row goes.
    Timer {
        id: completeTimer
        interval: 350
        onTriggered: Todoist.complete(root.task.id)
    }

    ColumnLayout {
        id: col
        anchors.left: check.right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 0

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.task.content
            textFormat: Text.PlainText
            font.family: Metrics.uiFont
            font.pixelSize: 12
            font.strikeout: root.done
            color: Colors.text
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: [root.dueText() + (root.task.recurring ? " ↻" : ""), root.task.project, ...root.task.labels.map(l => "@" + l)].filter(s => s.trim() !== "").join(" · ")
            textFormat: Text.PlainText
            font.family: Metrics.uiFont
            font.pixelSize: 10
            color: root.task.overdue ? Colors.red : Colors.overlay0
        }
    }
}
