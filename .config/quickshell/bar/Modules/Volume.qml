import Quickshell.Services.Pipewire
import "../Theme"

// Volume of the default output. Click opens the audio card (../AudioCard.qml)
// on this bar's screen, right click mutes, scroll changes the volume.
Pill {
    id: root
    property string screenName: ""
    readonly property bool cardOpen: UiState.audioCardScreen === screenName
    bg: cardOpen ? Colors.red : Colors.yellow
    fg: Colors.mantle

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.ready
    readonly property real vol: ready ? sink.audio.volume : 0
    readonly property bool muted: ready && sink.audio.muted

    icon: cardOpen ? "close" : !ready || muted ? "volume_off" : vol <= 0 ? "volume_mute" : vol < 0.5 ? "volume_down" : "volume_up"
    value: ready ? Math.round(vol * 100) + "%" : ""

    onClicked: {
        const open = cardOpen;
        UiState.closePanels();
        UiState.audioCardScreen = open ? "" : screenName;
    }
    onRightClicked: {
        if (ready)
            sink.audio.muted = !sink.audio.muted;
    }
    onWheel: delta => {
        if (!ready)
            return;
        const step = 0.05;
        const next = sink.audio.volume + (delta > 0 ? step : -step);
        sink.audio.volume = Math.max(0, Math.min(1, next));
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
}
