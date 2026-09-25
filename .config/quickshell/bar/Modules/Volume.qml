import Quickshell.Services.Pipewire
import "../Theme"

// Replaces waybar's wireplumber module. Volume/mute are set directly on the
// Pipewire node -- no `pamixer`/`wpctl` shell-out needed (pamixer isn't even
// installed on this machine; the old on-click "pamixer -t" was already dead).
Pill {
    id: root
    bg: Colors.yellow
    fg: Colors.mantle

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.ready
    readonly property real vol: ready ? sink.audio.volume : 0
    readonly property bool muted: ready && sink.audio.muted

    icon: !ready || muted ? "volume_off"
        : vol <= 0 ? "volume_mute"
        : vol < 0.5 ? "volume_down"
        : "volume_up"
    value: ready ? Math.round(vol * 100) + "%" : ""
    label: "Volume: " + Math.round(vol * 100) + "%"

    onClicked: {
        if (ready) sink.audio.muted = !sink.audio.muted;
    }
    onWheel: delta => {
        if (!ready) return;
        const step = 0.05;
        const next = sink.audio.volume + (delta > 0 ? step : -step);
        sink.audio.volume = Math.max(0, Math.min(1, next));
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
}
