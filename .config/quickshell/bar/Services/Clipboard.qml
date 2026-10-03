pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history for the launcher's clipboard mode (../Launcher.qml),
// backed by cliphist. hyprland.lua starts the two `wl-paste --watch cliphist
// store` watchers (text and images) that fill it.
//
// Images get a thumbnail: their bytes are decoded once into
// ~/.cache/quickshell/clipboard/<id>.png (ids never get reused, so the cache
// never goes stale; entries cliphist has dropped are pruned on each load).
Singleton {
    id: root

    // [{id, text, image, thumb}], newest first.
    property var entries: []
    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/quickshell/clipboard"
    property int thumbRevision: 0

    function refresh() {
        listProc.running = true;
    }

    function copy(id: string) {
        if (!/^\d+$/.test(id))
            return;
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", id]);
    }

    function remove(id: string) {
        if (!/^\d+$/.test(id))
            return;
        // cliphist delete reads "<id>\t<preview>" lines; the id is enough.
        removeProc.command = ["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete', "sh", id];
        removeProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const entries = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab <= 0)
                        continue;
                    const id = line.slice(0, tab);
                    const preview = line.slice(tab + 1);
                    // e.g. "[[ binary data 15 KiB png 200x120 ]]"
                    const image = /^\[\[ binary data .* (png|jpe?g|webp|bmp|gif) /i.test(preview);
                    entries.push({
                        id: id,
                        text: image ? preview.replace(/^\[\[ binary data (.*) \]\]$/, "$1") : preview.replace(/\s+/g, " ").trim(),
                        image: image,
                        thumb: image ? "file://" + root.thumbDir + "/" + id + ".png" : ""
                    });
                }
                root.entries = entries;
                thumbProc.ids = entries.filter(e => e.image).map(e => e.id);
                thumbProc.running = true;
            }
        }
    }

    // Decode missing thumbnails, drop ones whose entry is gone.
    Process {
        id: thumbProc
        property var ids: []
        command: ["sh", "-c", `
            dir="$1"; shift
            mkdir -p "$dir"
            for f in "$dir"/*.png; do
                [ -e "$f" ] || continue
                id=$(basename "$f" .png)
                case " $* " in *" $id "*) ;; *) rm -f "$f" ;; esac
            done
            for id in "$@"; do
                [ -s "$dir/$id.png" ] || cliphist decode "$id" > "$dir/$id.png"
            done`, "sh", root.thumbDir, ...ids]
        onExited: root.thumbRevision++
    }

    Process {
        id: removeProc
        onExited: root.refresh()
    }
}
