import Quickshell.Io
import "../Theme"

// Replaces waybar's custom/darkman module. Display is now pushed by the
// "darkman" IpcHandler in shell.qml straight into Colors.mode -- no more
// polling `darkman get` on a SIGRTMIN+8 signal, since there's nothing to
// re-run: the mode is already known in-process.
Pill {
    id: root
    bg: Colors.mode === "dark" ? Colors.mauve : Colors.yellow
    fg: Colors.mantle
    icon: Colors.mode === "dark" ? "dark_mode" : "light_mode"
    label: Colors.mode === "dark"
        ? "Dark mode — click to switch to light"
        : "Light mode — click to switch to dark"

    onClicked: toggleProc.exec({ command: ["darkman", "toggle"] })

    Process { id: toggleProc }
}
