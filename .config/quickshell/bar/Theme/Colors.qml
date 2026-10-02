pragma Singleton
import QtQuick
import Quickshell

// Catppuccin Latte (light) / Mocha (dark) palette, mirroring the hex values
// from .config/waybar/colors-latte.css / colors-mocha.css. `mode` is pushed
// by the "darkman" IpcHandler in shell.qml (see .local/share/darkman/quickshell.sh)
// rather than polled, and every resolved color below animates on change, so a
// theme toggle crossfades instead of the hard cut waybar's CSS swap produced.
Singleton {
    id: root

    property string mode: "dark" // "dark" | "light"

    readonly property QtObject mocha: QtObject {
        readonly property color base: "#1e1e2e"
        readonly property color mantle: "#181825"
        readonly property color crust: "#11111b"
        readonly property color text: "#cdd6f4"
        readonly property color overlay0: "#6c7086"
        readonly property color red: "#f38ba8"
        readonly property color peach: "#fab387"
        readonly property color yellow: "#f9e2af"
        readonly property color green: "#a6e3a1"
        readonly property color teal: "#94e2d5"
        readonly property color mauve: "#cba6f7"
        readonly property color flamingo: "#f2cdcd"
    }

    readonly property QtObject latte: QtObject {
        readonly property color base: "#eff1f5"
        readonly property color mantle: "#e6e9ef"
        readonly property color crust: "#dce0e8"
        readonly property color text: "#4c4f69"
        readonly property color overlay0: "#9ca0b0"
        readonly property color red: "#d20f39"
        readonly property color peach: "#fe640b"
        readonly property color yellow: "#df8e1d"
        readonly property color green: "#40a02b"
        readonly property color teal: "#179299"
        readonly property color mauve: "#8839ef"
        readonly property color flamingo: "#dd7878"
    }

    readonly property QtObject active: mode === "light" ? latte : mocha

    property color base: active.base
    property color mantle: active.mantle
    property color crust: active.crust
    property color text: active.text
    property color overlay0: active.overlay0
    property color red: active.red
    property color peach: active.peach
    property color yellow: active.yellow
    property color green: active.green
    property color teal: active.teal
    property color mauve: active.mauve
    property color flamingo: active.flamingo

    Behavior on base {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on mantle {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on crust {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on text {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on overlay0 {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on red {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on peach {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on yellow {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on green {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on teal {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on mauve {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on flamingo {
        ColorAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
}
