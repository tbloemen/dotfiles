import Quickshell
import Quickshell.Io
import "../Theme"

// Replaces waybar's custom/power module -- static icon, opens the same rofi
// powermenu.
Pill {
    id: root
    bg: Colors.flamingo
    fg: Colors.mantle
    icon: "power_settings_new"

    onClicked: proc.startDetached()

    Process {
        id: proc
        command: [Quickshell.env("HOME") + "/.config/rofi/powermenu/powermenu.sh"]
    }
}
