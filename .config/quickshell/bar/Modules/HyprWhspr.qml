import QtQuick
import Quickshell.Io
import "../Theme"

// Replaces waybar's custom/hyprwhspr module. hyprwhspr is an external,
// separately-packaged tray script (not in this repo) -- hidden entirely if
// it isn't installed, same de-facto behavior as a broken exec in waybar.
Pill {
    id: root
    visible: available
    property bool available: false
    readonly property string scriptPath: "/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh"

    property string state: "stopped" // recording | ready | stopped | error

    bg: Colors.base
    fg: state === "recording" ? Colors.red
        : state === "ready" ? Colors.green
        : state === "error" ? Colors.peach
        : Colors.overlay0
    icon: state === "recording" ? "mic" : state === "error" ? "error" : "mic_off"

    onClicked: actionProc.exec({ command: [scriptPath, "record"] })
    onRightClicked: actionProc.exec({ command: [scriptPath, "restart"] })

    // Ports waybar's CSS "@keyframes pulse" on #custom-hyprwhspr.recording.
    SequentialAnimation {
        running: root.state === "recording"
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "opacity"; from: 1; to: 0.4; duration: 500 }
        NumberAnimation { target: root; property: "opacity"; from: 0.4; to: 1; duration: 500 }
    }

    Process {
        id: availabilityCheck
        stdout: StdioCollector {}
        onExited: exitCode => {
            root.available = exitCode === 0;
            if (root.available) pollTimer.start();
        }
    }
    Component.onCompleted: availabilityCheck.exec({ command: ["test", "-x", root.scriptPath] })

    Process {
        id: statusProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data.class) root.state = data.class;
                } catch (e) {
                    // malformed/partial output -- keep the last known state
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        onTriggered: statusProc.exec({ command: [root.scriptPath, "status"] })
    }

    Process { id: actionProc }
}
