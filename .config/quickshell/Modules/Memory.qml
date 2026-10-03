import QtQuick
import Quickshell
import Quickshell.Io
import "../Theme"

// Replaces waybar's memory module (interval: 5s). Reads /proc/meminfo
// directly instead of shelling out to `free`.
Pill {
    id: root
    bg: Colors.peach
    fg: Colors.mantle
    icon: "memory"
    value: percent + "%"

    property int percent: 0

    // Preset 4 in the btop configs is mem + proc only.
    // The config is picked per darkman mode, same as the `btop` alias in .zshrc.
    onClicked: Quickshell.execDetached(["ghostty", "-e", "sh", "-c", "exec btop -c \"$HOME/.config/btop/btop_$(darkman get).conf\" -p 4"])

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: root.percent = parseInt(text, 10) || 0
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.exec({
            command: ["awk", "/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{printf \"%d\", (t-a)*100/t}", "/proc/meminfo"]
        })
    }
}
