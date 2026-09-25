import QtQuick
import "../Theme"

// Replaces waybar's clock module. waybar's {calendar} tooltip (a full month
// grid) is deliberately not reimplemented -- out of scope for this pass, see
// the migration plan's open risks; the full date is available on hover via
// the shared Pill hover-expand instead.
Pill {
    id: root
    bg: Colors.mauve
    fg: Colors.mantle
    icon: "schedule"
    value: Qt.formatDateTime(now, "HH:mm")
    label: Qt.formatDateTime(now, "ddd, d MMM yyyy")

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
