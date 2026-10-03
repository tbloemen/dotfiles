pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Pipewire nodes for the audio card (../AudioCard.qml): output and input
// devices, and the apps currently playing.
//
// Filtered on the node type flags: the internal nodes (the Scarlett's
// loopback/split filters, its raw hw input) carry none, so they stay out of
// the device lists. (`properties` would say more, but it's empty until a node
// is tracked, so it can't drive the filter.)
Singleton {
    id: root

    readonly property var nodes: Pipewire.nodes.values

    function ofType(type: int): var {
        return nodes.filter(n => n.type === type).sort((a, b) => label(a).localeCompare(label(b)));
    }

    readonly property var sinks: ofType(PwNodeType.AudioSink)
    readonly property var sources: ofType(PwNodeType.AudioSource)
    readonly property var streams: ofType(PwNodeType.AudioOutStream)

    // A node's volume/mute are only live while something tracks it.
    PwObjectTracker {
        objects: root.sinks.concat(root.sources, root.streams)
    }

    function label(node: var): string {
        if (node === null)
            return "";
        const p = node.properties;
        if (node.isStream)
            return p["application.name"] || node.description || node.name;
        return node.description || node.nickname || node.name;
    }

    // What an app stream is playing, e.g. a browser tab's title.
    function streamDetail(node: var): string {
        const media = node.properties["media.name"] ?? "";
        return media === label(node) ? "" : media;
    }

    function streamIcon(node: var): string {
        const p = node.properties;
        const name = p["application.icon-name"] || p["application.process.binary"] || "";
        return name ? Quickshell.iconPath(name, true) : "";
    }
}
