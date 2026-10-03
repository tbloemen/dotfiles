pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "../Theme"

// The notification daemon, replacing dunst. Owns org.freedesktop.Notifications
// for as long as quickshell runs.
//
// Every incoming notification is tracked, and the server's tracked list *is*
// the history the notification center shows -- so actions stay invokable
// from there. A popup is just a flag on top of that: `popups` maps a
// notification id to a serial number, and hiding the toast drops the id
// without touching the notification itself. The serial changes every time a
// notification is (re)shown, which is how a card knows to restart its timer
// when an app replaces a notification in place.
Singleton {
    id: root

    readonly property int historyLength: 20 // dunst's history_length

    readonly property alias server: server
    readonly property var history: server.trackedNotifications.values

    property var popups: ({})
    readonly property int popupCount: Object.keys(popups).length
    // Screen the toasts are on: whichever monitor had focus when the latest
    // one arrived.
    property string popupScreen: ""

    property bool dnd: false
    property int unread: 0

    // Arrival times, for the "2m ago" labels. `now` ticks so they stay fresh.
    property var times: ({})
    property real now: Date.now()

    // Fallbacks when the app leaves the timeout to the server, same values
    // dunstrc had per urgency. Critical never times out.
    function timeoutFor(n: Notification): int {
        if (n.expireTimeout > 0)
            return n.expireTimeout * 1000;
        if (n.expireTimeout === 0 || n.urgency === NotificationUrgency.Critical)
            return 0;
        return n.urgency === NotificationUrgency.Low ? 4000 : 6000;
    }

    property int serial: 0
    function showPopup(n: Notification) {
        const p = Object.assign({}, popups);
        p[n.id] = ++serial;
        popups = p;
        popupScreen = Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
    }

    function hidePopup(n: Notification) {
        if (!(n.id in popups))
            return;
        const p = Object.assign({}, popups);
        delete p[n.id];
        popups = p;
        // Transient notifications aren't meant to linger in history.
        if (n.transient)
            n.expire();
    }

    function clearPopups() {
        for (const n of history.slice())
            if (n.id in popups)
                hidePopup(n);
        popups = {};
    }

    function clearAll() {
        popups = {};
        for (const n of history.slice())
            n.dismiss();
        unread = 0;
    }

    function markRead() {
        unread = 0;
    }

    function ageOf(n: Notification): string {
        const t = times[n.id];
        if (t === undefined)
            return "";
        const s = Math.max(0, Math.floor((now - t) / 1000));
        if (s < 60)
            return "now";
        if (s < 3600)
            return Math.floor(s / 60) + "m ago";
        if (s < 86400)
            return Math.floor(s / 3600) + "h ago";
        return Math.floor(s / 86400) + "d ago";
    }

    function iconSource(n: Notification): string {
        if (n.image)
            return n.image;
        const icon = n.appIcon;
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.includes("://"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }

    function arrived(n: Notification, isUpdate: bool) {
        const t = Object.assign({}, times);
        t[n.id] = Date.now();
        times = t;

        // With the center open the notification shows up in its list right
        // away, so neither a toast nor an unread badge is needed.
        if (UiState.notifCenterScreen !== "")
            return;
        if (!isUpdate)
            unread++;
        if (!dnd || n.urgency === NotificationUrgency.Critical)
            showPopup(n);
    }

    property var pendingUpdates: ({})
    function queueUpdate(n: Notification) {
        pendingUpdates[n.id] = n;
        Qt.callLater(flushUpdates);
    }
    function flushUpdates() {
        const pending = pendingUpdates;
        pendingUpdates = {};
        for (const id in pending)
            arrived(pending[id], true);
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            root.arrived(n, false);

            // Apps can update a notification in place (same id) instead of
            // sending a new one, e.g. progress updates. Re-show it, but
            // don't count it as unread again. Summary and body usually change
            // together, so coalesce them into one refresh.
            const refresh = () => root.queueUpdate(n);
            n.summaryChanged.connect(refresh);
            n.bodyChanged.connect(refresh);

            n.closed.connect(() => {
                if (n.id in root.popups) {
                    const p = Object.assign({}, root.popups);
                    delete p[n.id];
                    root.popups = p;
                }
                const t = Object.assign({}, root.times);
                delete t[n.id];
                root.times = t;
            });

            const tracked = root.history;
            for (let i = 0; i < tracked.length - root.historyLength; i++)
                tracked[i].dismiss();
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }
}
