import QtQuick
import Quickshell.Hyprland
import "../Theme"

// Replaces waybar's hyprland/workspaces module. Workspace switching must use
// hyprland.lua's Lua dispatcher form (hl.dsp.focus({ workspace = N })) rather
// than the classic "workspace N" string -- hyprland.lua parses every
// `hyprctl dispatch`/IPC dispatch argument as a Lua expression, so the bare
// classic form is a syntax error under this config (see CLAUDE.md's
// "hyprctl dispatch is Lua too" note; verified live against this exact
// config: `hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'` switches,
// `hyprctl dispatch "workspace 3"` errors).
Item {
    id: root
    property string screenName: ""

    implicitWidth: row.implicitWidth
    implicitHeight: Metrics.pillHeight

    readonly property var pinnedIds: [1, 2, 3, 4, 5]

    function workspaceList() {
        return Hyprland.workspaces.values;
    }

    function belongsHere(ws) {
        // No monitor info yet (still loading) -- don't hide it.
        return !ws.monitor || !root.screenName || ws.monitor.name === root.screenName;
    }

    function computeIds() {
        const ids = new Set(pinnedIds);
        const list = workspaceList();
        for (let i = 0; i < list.length; i++) {
            const ws = list[i];
            if (pinnedIds.includes(ws.id) || belongsHere(ws)) ids.add(ws.id);
        }
        return Array.from(ids).sort((a, b) => a - b);
    }

    function workspaceFor(id) {
        const list = workspaceList();
        for (let i = 0; i < list.length; i++) if (list[i].id === id) return list[i];
        return null;
    }

    property var ids: computeIds()
    property var activeDelegate: null

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { root.ids = root.computeIds(); }
    }

    // Animation idea #1: a solid indicator that slides/resizes to the active
    // workspace instead of each pill just recoloring instantly.
    Rectangle {
        id: indicator
        radius: Metrics.radius
        color: Colors.text
        height: Metrics.pillHeight
        x: root.activeDelegate ? root.activeDelegate.x : 0
        width: root.activeDelegate ? root.activeDelegate.width : 0
        visible: root.activeDelegate !== null

        Behavior on x { NumberAnimation { duration: Metrics.animFast; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: Metrics.animFast; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Metrics.animMedium } }
    }

    Row {
        id: row
        spacing: 4

        Repeater {
            model: root.ids

            delegate: Rectangle {
                id: delegate
                required property int modelData
                property var ws: root.workspaceFor(modelData)
                // ws.active means "active on ITS OWN monitor" -- a global
                // fact about the workspace, not scoped to whichever bar
                // instance is asking. Without the belongsHere() check, a
                // pinned id that's actually active on the OTHER monitor
                // would steal this bar's sliding indicator and highlight
                // color (confirmed live: workspace 4, active on HDMI-A-1,
                // was rendering as "active" on the eDP-1 bar too).
                property bool active: ws ? (ws.active && root.belongsHere(ws)) : false
                property bool urgent: ws ? ws.urgent : false

                width: label.implicitWidth + Metrics.paddingH
                height: Metrics.pillHeight
                radius: Metrics.radius
                color: urgent ? Colors.red : "transparent"

                Behavior on color { ColorAnimation { duration: Metrics.animMedium } }

                onActiveChanged: if (active) root.activeDelegate = delegate
                Component.onCompleted: if (active) root.activeDelegate = delegate

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: delegate.urgent ? "priority_high" : String(delegate.modelData)
                    font.family: delegate.urgent ? Metrics.iconFont : Metrics.uiFont
                    font.pixelSize: delegate.urgent ? Metrics.iconSize : Metrics.textSize
                    color: delegate.active ? Colors.base : Colors.text
                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }
                }

                TapHandler {
                    onTapped: Hyprland.dispatch("hl.dsp.focus({ workspace = " + delegate.modelData + " })")
                }
            }
        }
    }
}
