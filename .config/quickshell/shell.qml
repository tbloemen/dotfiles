import QtQuick
import Quickshell
import "bar" as BarConfig // qmllint disable unused-imports

ShellRoot {
    Loader {
        source: "bar/shell.qml"
    }
}
