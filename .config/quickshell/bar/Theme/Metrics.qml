pragma Singleton
import Quickshell

Singleton {
    readonly property int barHeight: 34
    readonly property int pillHeight: 26
    readonly property int radius: 6
    readonly property int gap: 6
    readonly property int paddingH: 10
    readonly property int iconSize: 16
    readonly property int textSize: 13
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property string uiFont: "JetBrainsMono Nerd Font"

    readonly property int animFast: 160 // hover-expand, workspace pill slide
    readonly property int animMedium: 220 // theme crossfade, icon state morph
    readonly property int animSlow: 400 // startup reveal
}
