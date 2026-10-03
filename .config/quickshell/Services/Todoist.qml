pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Todoist tasks due today or overdue, for the pill
// (Modules/TodoistIndicator.qml), the Todoist card (TodoistCard.qml) and the
// calendar card. All API calls go through scripts/todoist.py, which takes
// the token from the GNOME keyring (`secret-tool store --label=Todoist
// service todoist`). Refreshed every five minutes, when a card opens and
// after every change.
Singleton {
    id: root

    // [{id, content, priority (1 = p1), project, projectColor, labels, due,
    //   time, recurring, overdue}], overdue first, then by time and priority.
    property var tasks: []
    readonly property int count: tasks.length
    readonly property int overdueCount: tasks.filter(t => t.overdue).length
    property bool loading: false
    property string error: "" // "no-token", or what the last call failed with

    // For the quick-add autocomplete: [{name, color}].
    property var projects: []
    property var labels: []

    // A quick add went through; Todoist's parsed title for the task.
    signal added(content: string)

    readonly property string script: Quickshell.shellPath("scripts/todoist.py")

    // A refresh asked for while one runs (say, right after completing a
    // task) runs again afterwards, so the list can't come back stale.
    property bool refreshQueued: false

    function refresh() {
        if (listProc.running) {
            refreshQueued = true;
            return;
        }
        loading = true;
        listProc.running = true;
    }

    function loadMeta() {
        if (!metaProc.running)
            metaProc.running = true;
    }

    // Optimistic: the task leaves the list right away; the refresh after
    // the call brings it back if closing failed.
    function complete(id: string) {
        tasks = tasks.filter(t => t.id !== id);
        run(["close", id]);
    }

    function quickAdd(text: string) {
        if (text.trim() !== "")
            run(["quick", text.trim()]);
    }

    function openTask(id: string) {
        Apps.openUrl("https://app.todoist.com/app/task/" + id);
    }

    function openApp() {
        Apps.openUrl("https://app.todoist.com/app/today");
    }

    function parse(text: string): var {
        try {
            return JSON.parse(text);
        } catch (e) {
            return {
                error: "bad output from todoist.py"
            };
        }
    }

    function sorted(list: var): var {
        // Date-only dues sort before timed ones on the same day, like Todoist.
        return list.slice().sort((a, b) => (b.overdue - a.overdue) || a.due.localeCompare(b.due) || a.priority - b.priority);
    }

    // Each action gets its own process, so completing two tasks in quick
    // succession doesn't drop one.
    function run(args: var) {
        actionProc.createObject(root, {
            command: [script, ...args]
        });
    }

    Component {
        id: actionProc

        Process {
            id: proc
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    const r = root.parse(text);
                    if (r.error)
                        root.error = r.error;
                    else if (proc.command[1] === "quick")
                        root.added(r.content);
                    root.refresh();
                    proc.destroy();
                }
            }
        }
    }

    Process {
        id: listProc
        command: [root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const r = root.parse(text);
                root.loading = false;
                if (root.refreshQueued) {
                    root.refreshQueued = false;
                    root.refresh();
                    return;
                }
                if (Array.isArray(r)) {
                    root.tasks = root.sorted(r);
                    root.error = "";
                } else {
                    root.error = r.error ?? "unknown error";
                    // Without a token there's nothing to show; on a network
                    // hiccup keep what we had.
                    if (root.error === "no-token")
                        root.tasks = [];
                }
            }
        }
    }

    Process {
        id: metaProc
        command: [root.script, "meta"]
        stdout: StdioCollector {
            onStreamFinished: {
                const r = root.parse(text);
                if (r.projects) {
                    root.projects = r.projects;
                    root.labels = r.labels;
                }
            }
        }
    }

    Timer {
        // Without a token, look again every 30 s (only a keyring lookup, no
        // API call), so storing one shows the pill without a qs restart.
        interval: root.error === "no-token" ? 30 * 1000 : 5 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
