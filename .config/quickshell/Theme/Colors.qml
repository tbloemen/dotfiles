pragma Singleton
import QtQuick
import Quickshell

// Catppuccin Latte (light) / Mocha (dark) palette, ported from the hex values
// of the former waybar colors-latte.css / colors-mocha.css. `mode` is pushed
// by the "darkman" IpcHandler in shell.qml (see .local/share/darkman/quickshell.sh)
// rather than polled, and every resolved color below animates on change, so a
// theme toggle crossfades instead of the hard cut waybar's CSS swap produced.
Singleton {
    id: root

    property string mode: "dark" // "dark" | "light"

    // One flavour's colors, typed so `active.<name>` resolves for qmllint.
    component Palette: QtObject {
        property color base
        property color mantle
        property color crust
        property color surface0
        property color surface1
        property color text
        property color subtext0
        property color overlay0
        property color red
        property color peach
        property color yellow
        property color green
        property color teal
        property color mauve
        property color flamingo
        property color lavender
    }

    readonly property Palette mocha: Palette {
        base: "#1e1e2e"
        mantle: "#181825"
        crust: "#11111b"
        surface0: "#313244"
        surface1: "#45475a"
        text: "#cdd6f4"
        subtext0: "#a6adc8"
        overlay0: "#6c7086"
        red: "#f38ba8"
        peach: "#fab387"
        yellow: "#f9e2af"
        green: "#a6e3a1"
        teal: "#94e2d5"
        mauve: "#cba6f7"
        flamingo: "#f2cdcd"
        lavender: "#b4befe"
    }

    readonly property Palette latte: Palette {
        base: "#eff1f5"
        mantle: "#e6e9ef"
        crust: "#dce0e8"
        surface0: "#ccd0da"
        surface1: "#bcc0cc"
        text: "#4c4f69"
        subtext0: "#6c6f85"
        overlay0: "#9ca0b0"
        red: "#d20f39"
        peach: "#fe640b"
        yellow: "#df8e1d"
        green: "#40a02b"
        teal: "#179299"
        mauve: "#8839ef"
        flamingo: "#dd7878"
        lavender: "#7287fd"
    }

    readonly property Palette active: mode === "light" ? latte : mocha

    property color base: active.base
    property color mantle: active.mantle
    property color crust: active.crust
    property color surface0: active.surface0
    property color surface1: active.surface1
    property color text: active.text
    property color subtext0: active.subtext0
    property color overlay0: active.overlay0
    property color red: active.red
    property color peach: active.peach
    property color yellow: active.yellow
    property color green: active.green
    property color teal: active.teal
    property color mauve: active.mauve
    property color flamingo: active.flamingo
    property color lavender: active.lavender

    Behavior on base {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on mantle {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on crust {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on text {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on overlay0 {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on red {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on peach {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on yellow {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on green {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on teal {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on mauve {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on flamingo {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on surface0 {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on surface1 {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on subtext0 {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
    Behavior on lavender {
        ColorAnimation {
            duration: Metrics.animTheme
            easing.type: Metrics.animThemeEasing
        }
    }
}
