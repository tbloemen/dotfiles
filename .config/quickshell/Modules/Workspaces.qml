import QtQuick
import Quickshell.Hyprland
import "../Theme"

Item {
    id: root
    property string screenName: ""

    implicitWidth: row.implicitWidth
    implicitHeight: Metrics.pillHeight

    function belongsHere(ws) {
        // No monitor info yet (still loading) -- don't hide it.
        return !ws.monitor || !root.screenName || ws.monitor.name === root.screenName;
    }

    function workspaceFor(id) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id)
                return list[i];
        return null;
    }

    readonly property var ids: Hyprland.workspaces.values.filter(ws => ws.id > 0 && root.belongsHere(ws)).map(ws => ws.id).sort((a, b) => a - b)
    property var activeDelegate: null

    Row {
        id: row
        spacing: Metrics.gap

        Repeater {
            model: root.ids

            delegate: Rectangle {
                id: delegate
                required property int modelData
                property var ws: root.workspaceFor(modelData)
                // ws.active means "active on ITS OWN monitor"; every id shown
                // here lives on this bar's monitor, so that's the right scope.
                property bool active: ws ? ws.active : false
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
                layer.enabled: true
                layer.effect: PillShadow {}

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
