pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Monitor state and layout changes for the display card (../DisplayCard.qml),
// replacing the old ~/scripts/{external_only,restore_default}.sh.
//
// Those scripts used `hyprctl keyword monitor`, which Hyprland refuses under
// the Lua config ("keyword can't work with non-legacy parsers"), so changes
// go through `hyprctl eval 'hl.monitor({...})'` instead. Like the scripts,
// they last until Hyprland reloads its config, which re-applies the
// hl.monitor blocks in hyprland.lua (= the "Extend" layout below).
//
// Quickshell's Hyprland.monitors leaves out disabled monitors, so the list
// comes from `hyprctl monitors all -j`, re-read whenever Hyprland reports a
// monitor change.
Singleton {
    id: root

    property var monitors: []
    readonly property var internal: monitors.find(m => isInternal(m)) ?? null
    readonly property var externals: monitors.filter(m => !isInternal(m))
    readonly property int enabledCount: monitors.filter(m => !m.disabled).length

    // Which preset the current state matches, if any.
    readonly property string layout: {
        if (monitors.length === 0)
            return "";
        if (monitors.some(m => m.mirrorOf && m.mirrorOf !== "none"))
            return "mirror";
        if (internal !== null && internal.disabled)
            return "external";
        if (externals.length > 0 && externals.every(m => m.disabled))
            return "laptop";
        return "extend";
    }

    function isInternal(m): bool {
        return /^(eDP|LVDS|DSI)/.test(m.name);
    }

    function refresh() {
        listProc.running = true;
    }

    // The position/scale each monitor gets in hyprland.lua, so a layout or
    // mode change ends up where the config would put it.
    function placement(m): string {
        return isInternal(m) ? 'position = "auto", scale = "1"' : 'position = "auto-left", scale = "auto"';
    }

    function rule(m, extra: string): string {
        return 'hl.monitor({ output = "' + m.name + '", ' + extra + ' })';
    }

    // `disabled = false` has to be explicit: a monitor that was switched off
    // stays off under a rule that leaves it out (hyprctl still says "ok").
    function enabledRule(m, mode: string): string {
        return rule(m, 'mode = "' + (mode || "preferred") + '", ' + placement(m) + ', disabled = false');
    }

    function apply(rules: var) {
        if (rules.length === 0)
            return;
        Quickshell.execDetached(["hyprctl", "eval", rules.join("\n")]);
    }

    function setLayout(name: string) {
        const all = monitors;
        if (all.length < 2 && name !== "extend")
            return;
        const inner = internal ?? all[0];
        const rules = [];
        for (const m of all) {
            const isInner = m === inner;
            if (name === "laptop")
                rules.push(isInner ? enabledRule(m) : rule(m, "disabled = true"));
            else if (name === "external")
                rules.push(isInner ? rule(m, "disabled = true") : enabledRule(m));
            else if (name === "mirror")
                rules.push(isInner ? enabledRule(m) : rule(m, 'mode = "preferred", position = "auto", scale = "auto", mirror = "' + inner.name + '"'));
            else
                rules.push(enabledRule(m));
        }
        apply(rules);
    }

    function setEnabled(m, enabled: bool) {
        // Never switch off the last screen.
        if (!enabled && enabledCount <= 1)
            return;
        apply([enabled ? enabledRule(m) : rule(m, "disabled = true")]);
    }

    // Unplugging the only enabled screen (e.g. HDMI in "external only")
    // leaves just disabled ones behind, i.e. a black screen with no way to
    // reach the card. Turn the laptop panel (or whatever is left) back on.
    function ensureOneEnabled() {
        if (monitors.length === 0 || enabledCount > 0)
            return;
        apply([enabledRule(internal ?? monitors[0])]);
    }

    function setMode(m, mode: string) {
        apply([enabledRule(m, mode.replace(/Hz$/, ""))]);
    }

    Process {
        id: listProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    // When the last real output goes, Hyprland puts in a
                    // headless "FALLBACK" monitor, which would otherwise
                    // count as an enabled screen.
                    root.monitors = JSON.parse(text).filter(m => m.name !== "FALLBACK");
                } catch (e) {
                    return;
                }
                root.ensureOneEnabled();
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2", "configreloaded"].includes(event.name))
                refreshDelay.restart();
        }
    }

    // Hyprland sends several events per change; read once they've settled.
    Timer {
        id: refreshDelay
        interval: 250
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
