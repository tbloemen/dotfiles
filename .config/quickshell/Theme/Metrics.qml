pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property int barHeight: 42
    readonly property int pillHeight: 30
    readonly property int radius: 4
    readonly property int gap: 6 // between pills; waybar: 3px margin per side
    readonly property int paddingH: 10
    readonly property int workspacePaddingH: 18 // waybar: #workspaces button padding
    readonly property int iconSize: 14
    readonly property int textSize: 13
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property string uiFont: "JetBrainsMono Nerd Font"

    readonly property int animFast: 160 // hover-expand, workspace pill slide
    readonly property int animMedium: 220 // icon state morph, highlight slide
    // Light/dark switch: the bar's colors (Colors.qml) and the wallpaper
    // crossfade (WallpaperWindow.qml) share this so they move as one.
    readonly property int animTheme: 500
    readonly property int animThemeEasing: Easing.InOutCubic
    readonly property int animSlow: 400 // startup reveal
}
