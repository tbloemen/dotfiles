import QtQuick
import Quickshell.Hyprland
import "../Theme"

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
            if (pinnedIds.includes(ws.id) || belongsHere(ws))
                ids.add(ws.id);
        }
        return Array.from(ids).sort((a, b) => a - b);
    }

    function workspaceFor(id) {
        const list = workspaceList();
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id)
                return list[i];
        return null;
    }

    property var ids: computeIds()
    property var activeDelegate: null

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            root.ids = root.computeIds();
        }
    }

    Row {
        id: row
        spacing: Metrics.gap

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

                width: label.implicitWidth + Metrics.workspacePaddingH * 2
                height: Metrics.pillHeight
                radius: Metrics.radius
                color: urgent ? Colors.red : Colors.base
                // Unlike waybar, outline the pills so they read against the
                // bar's mantle. Hidden on the active one, which the indicator
                // covers anyway, so its corners don't fringe.
                border.width: 1
                border.color: active ? "transparent" : Colors.surface1

                Behavior on color {
                    ColorAnimation {
                        duration: Metrics.animMedium
                    }
                }

                onActiveChanged: if (active)
                    root.activeDelegate = delegate
                Component.onCompleted: if (active)
                    root.activeDelegate = delegate

                Text {
                    id: label
                    parent: labels
                    x: delegate.x + Math.round((delegate.width - width) / 2)
                    y: Math.round((labels.height - height) / 2)
                    text: delegate.urgent ? "priority_high" : String(delegate.modelData)
                    font.family: delegate.urgent ? Metrics.iconFont : Metrics.uiFont
                    font.pixelSize: delegate.urgent ? Metrics.iconSize : Metrics.textSize
                    color: delegate.active ? Colors.base : Colors.text
                    Behavior on color {
                        ColorAnimation {
                            duration: Metrics.animFast
                        }
                    }
                }

                TapHandler {
                    onTapped: Hyprland.dispatch("hl.dsp.focus({ workspace = " + delegate.modelData + " })")
                }
            }
        }
    }

    // Animation idea #1: a solid indicator that slides/resizes to the active
    // workspace instead of each pill just recoloring instantly. Stacked
    // between the pill backgrounds (the Row above) and the labels (below), so
    // it slides over the opaque inactive pills without hiding the numbers.
    Rectangle {
        id: indicator
        radius: Metrics.radius
        color: Colors.text
        height: Metrics.pillHeight
        x: root.activeDelegate ? root.activeDelegate.x : 0
        width: root.activeDelegate ? root.activeDelegate.width : 0
        visible: root.activeDelegate !== null

        Behavior on x {
            NumberAnimation {
                duration: Metrics.animFast
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Metrics.animFast
                easing.type: Easing.OutCubic
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Metrics.animMedium
            }
        }
    }

    // The delegates' labels are reparented here so they draw above the
    // indicator; QML z-order only applies among siblings.
    Item {
        id: labels
        anchors.fill: parent
    }
}
