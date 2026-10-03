pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

// State for the volume/brightness OSD (../OsdWindow.qml renders it, one per
// screen, only on `screen`), which doubles as the track-change toast (kind
// "track", fed by Media.qml). Shown for a moment after every change, then
// hides itself.
//
// Volume is observed rather than signalled: any change to the default sink
// -- media keys, scrolling the bar's volume pill, pavucontrol -- pops it.
// Brightness has no Quickshell service and sysfs `brightness` doesn't emit
// inotify events, so hyprland.lua's brightness binds poke it over IPC
// (`qs ipc call osd brightness`) and it reads the level back from brightnessctl.
Singleton {
    id: root

    property bool shown: false
    property string screen: ""
    property string kind: "level" // "level" (volume/brightness) | "track"
    // kind "track": what's now playing.
    property string title: ""
    property string subtitle: ""
    property string art: ""
    property string icon: ""
    property real value: 0 // 0..1
    property bool muted: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink !== null && sink.ready

    // Pipewire reports the initial volume (and the default sink switching)
    // as a change, so only react once the sink has settled.
    property bool armed: false
    onSinkChanged: {
        armed = false;
        armTimer.restart();
    }
    Timer {
        id: armTimer
        interval: 1000
        running: true
        onTriggered: root.armed = true
    }

    function show(icon: string, value: real, muted: bool) {
        kind = "level";
        root.icon = icon;
        root.value = Math.max(0, Math.min(1, value));
        root.muted = muted;
        popUp(1500);
    }

    function showTrack(title: string, subtitle: string, art: string) {
        kind = "track";
        root.title = title;
        root.subtitle = subtitle;
        root.art = art;
        popUp(3000);
    }

    function popUp(duration: int) {
        screen = Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
        shown = true;
        hideTimer.interval = duration;
        hideTimer.restart();
    }

    function showVolume() {
        if (!armed || !sinkReady)
            return;
        const vol = sink.audio.volume;
        const muted = sink.audio.muted;
        show(muted ? "volume_off" : vol <= 0 ? "volume_mute" : vol < 0.5 ? "volume_down" : "volume_up", vol, muted);
    }

    function brightness() {
        brightnessProc.running = true;
    }

    Connections {
        target: root.sinkReady ? root.sink.audio : null
        function onVolumeChanged() {
            root.showVolume();
        }
        function onMutedChanged() {
            root.showVolume();
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // `brightnessctl -m` prints e.g. "amdgpu_bl2,backlight,123,48%,255".
    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pct = parseInt(text.split(",")[3]);
                if (isNaN(pct))
                    return;
                root.show(pct < 34 ? "brightness_low" : pct < 67 ? "brightness_medium" : "brightness_high", pct / 100, false);
            }
        }
    }

    Timer {
        id: hideTimer
        onTriggered: root.shown = false
    }
}
