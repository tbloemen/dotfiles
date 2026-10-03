import QtQuick
import QtQuick.Layouts
import "Theme"
import "Services"

// Todoist card, unfolding out of the Todoist pill (on Card.qml): what's due
// today or overdue (Services/Todoist.qml), plus a quick-add field.
//
// Quick add hands the text to Todoist's own parser, so "Call mom tomorrow
// 5pm #Home @phone p1" sets the date, project, label and priority. Typing
// # or @ suggests your projects / labels: ↑↓ pick, Tab or Enter fills one
// in; otherwise Enter adds the task.
Card {
    id: root

    screenProp: "todoistCardScreen"
    namespace: "todoistcard"
    align: "right"
    cardWidth: 340

    property string addedText: ""
    property int suggestionIndex: 0

    onOpened: {
        input.text = "";
        addedText = "";
        Todoist.refresh();
        Todoist.loadMeta();
        input.forceActiveFocus();
    }

    // The #project / @label word the cursor is at the end of, if any.
    // Quick Add wants spaces in names escaped: #My\ Project.
    readonly property var token: {
        const before = input.text.slice(0, input.cursorPosition);
        const m = before.match(/(?:^|\s)([#@])((?:\\ |[^\s#@])*)$/);
        return m ? {
            sigil: m[1],
            query: m[2].replace(/\\ /g, " "),
            start: before.length - m[1].length - m[2].length
        } : null;
    }
    // The word already names one, so Enter adds the task rather than
    // completing to a longer name (#Home, not #Homework).
    readonly property bool exactToken: token !== null && (token.sigil === "#" ? Todoist.projects : Todoist.labels).some(p => p.name.toLowerCase() === token.query.toLowerCase())

    readonly property var suggestions: {
        if (token === null)
            return [];
        const q = token.query.toLowerCase();
        const pool = token.sigil === "#" ? Todoist.projects : Todoist.labels;
        // Prefix matches first, then anywhere in the name.
        return pool.map(p => ({
                    item: p,
                    at: p.name.toLowerCase().indexOf(q)
                })).filter(r => r.at >= 0 && r.item.name.toLowerCase() !== q).sort((a, b) => (a.at !== 0) - (b.at !== 0) || a.item.name.localeCompare(b.item.name)).slice(0, 6).map(r => r.item);
    }
    onSuggestionsChanged: suggestionIndex = 0

    function accept(s) {
        const t = token;
        const end = input.cursorPosition;
        const insert = t.sigil + s.name.replace(/ /g, "\\ ") + " ";
        input.text = input.text.slice(0, t.start) + insert + input.text.slice(end);
        input.cursorPosition = t.start + insert.length;
    }

    function submit() {
        if (input.text.trim() === "")
            return;
        Todoist.quickAdd(input.text);
        input.text = "";
    }

    Connections {
        target: Todoist
        function onAdded(content: string) {
            root.addedText = content;
            addedTimer.restart();
        }
    }

    Timer {
        id: addedTimer
        interval: 4000
        onTriggered: root.addedText = ""
    }

    // Header: title, refresh, open Todoist.
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 2

        Text {
            text: "Today"
            font.family: Metrics.uiFont
            font.pixelSize: 13
            font.bold: true
            color: Colors.text
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            text: Todoist.overdueCount > 0 ? Todoist.count + " tasks · " + Todoist.overdueCount + " overdue" : Todoist.count === 1 ? "1 task" : Todoist.count + " tasks"
            visible: Todoist.error !== "no-token"
            font.family: Metrics.uiFont
            font.pixelSize: 11
            color: Colors.overlay0
        }

        HeaderButton {
            icon: "refresh"
            accent: Colors.subtext0
            enabled: !Todoist.loading
            onClicked: Todoist.refresh()
        }
        HeaderButton {
            icon: "open_in_new"
            accent: Colors.subtext0
            onClicked: {
                Todoist.openApp();
                root.close();
            }
        }
    }

    // Quick add.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 34
        radius: 6
        color: Colors.base
        border.width: input.activeFocus ? 1 : 0
        border.color: Colors.green

        Text {
            id: addIcon
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "add"
            font.family: Metrics.iconFont
            font.pixelSize: 18
            color: Colors.green
        }

        TextInput {
            id: input
            anchors.left: addIcon.right
            anchors.right: parent.right
            anchors.leftMargin: 6
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            font.family: Metrics.uiFont
            font.pixelSize: 12
            color: Colors.text
            selectionColor: Colors.surface1
            selectedTextColor: Colors.text

            Keys.onPressed: event => {
                const n = root.suggestions.length;
                if (event.key === Qt.Key_Escape) {
                    if (input.text === "")
                        root.close();
                    else
                        input.text = "";
                } else if (n > 0 && (event.key === Qt.Key_Tab || !root.exactToken && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)))
                    root.accept(root.suggestions[root.suggestionIndex]);
                else if (n > 0 && event.key === Qt.Key_Down)
                    root.suggestionIndex = (root.suggestionIndex + 1) % n;
                else if (n > 0 && event.key === Qt.Key_Up)
                    root.suggestionIndex = (root.suggestionIndex + n - 1) % n;
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    root.submit();
                else
                    return;
                event.accepted = true;
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0
                text: "Add task — tomorrow 5pm #Project @label p1"
                font: input.font
                color: Colors.overlay0
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }

    // Autocomplete for the #project / @label being typed.
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.suggestions.length > 0
        spacing: 0

        Repeater {
            model: root.suggestions

            Rectangle {
                id: sug
                required property var modelData
                required property int index
                readonly property bool current: index === root.suggestionIndex
                Layout.fillWidth: true
                implicitHeight: 26
                radius: 6
                color: current ? Colors.surface0 : "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: root.token?.sigil ?? ""
                        font.family: Metrics.uiFont
                        font.pixelSize: 12
                        font.bold: true
                        color: sug.modelData.color
                    }
                    Text {
                        text: sug.modelData.name
                        textFormat: Text.PlainText
                        font.family: Metrics.uiFont
                        font.pixelSize: 12
                        color: Colors.text
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.suggestionIndex = sug.index
                    onClicked: {
                        root.accept(sug.modelData);
                        input.forceActiveFocus();
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        visible: root.addedText !== ""
        text: "Added “" + root.addedText + "”"
        textFormat: Text.PlainText
        elide: Text.ElideRight
        font.family: Metrics.uiFont
        font.pixelSize: 11
        color: Colors.green
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Colors.surface1
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: Todoist.count === 0 ? emptyText.implicitHeight + 24 : Math.min(list.implicitHeight, 360)

        Text {
            id: emptyText
            anchors.centerIn: parent
            width: parent.width - 16
            visible: Todoist.count === 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: Todoist.error === "no-token" ? "No Todoist token. Store one with\nsecret-tool store --label=Todoist service todoist" : Todoist.error !== "" ? "Couldn't reach Todoist\n" + Todoist.error : Todoist.loading ? "Loading…" : "All done for today"
            font.family: Metrics.uiFont
            font.pixelSize: 12
            color: Todoist.error !== "" ? Colors.red : Colors.overlay0
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
                spacing: 4

                Repeater {
                    model: Todoist.tasks

                    TodoistTask {
                        required property var modelData
                        Layout.fillWidth: true
                        task: modelData
                    }
                }
            }
        }
    }
}
