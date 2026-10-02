import QtQuick
import Quickshell // qmllint disable unused-imports
import Quickshell.Services.SystemTray
import "../Theme"

// Replaces waybar's tray module. Icons fade+scale in as they register
// (animation idea #4) rather than the row just abruptly reflowing.
//
// Known tray apps get a Material Symbols glyph in place of their own icon, so
// they match the other pills and follow the theme like any other text. The
// mapping keys off the freedesktop icon name the app reports (nm-applet and
// blueman change it with their state); anything unmapped falls back to the
// app's own icon.
Rectangle {
    id: root
    implicitWidth: row.implicitWidth + 24 // waybar: #tray padding 12px
    implicitHeight: Metrics.pillHeight
    visible: SystemTray.items.values.length > 0
    radius: Metrics.radius
    color: Colors.base
    // Same outline as the inactive workspace pills.
    border.width: 1
    border.color: Colors.surface1

    function glyphFor(iconUrl) {
        const m = String(iconUrl).match(/^image:\/\/icon\/([^?]+)/);
        const name = m ? m[1] : "";
        if (name.startsWith("nm-signal-")) {
            const strength = parseInt(name.slice("nm-signal-".length));
            return strength >= 100 ? "signal_wifi_4_bar" : strength >= 75 ? "network_wifi_3_bar" : strength >= 50 ? "network_wifi_2_bar" : strength >= 25 ? "network_wifi_1_bar" : "signal_wifi_0_bar";
        }
        if (name.startsWith("nm-device-wired"))
            return "lan";
        if (name.startsWith("nm-no-connection"))
            return "signal_wifi_off";
        if (name.startsWith("nm-stage") || name.startsWith("nm-vpn-connecting"))
            return "wifi_find";
        if (name.startsWith("nm-vpn"))
            return "vpn_lock";
        if (name.startsWith("nm-tech") || name.startsWith("nm-device-wwan") || name.startsWith("nm-wwan"))
            return "signal_cellular_alt";
        if (name.startsWith("blueman-disabled"))
            return "bluetooth_disabled";
        if (name.startsWith("blueman"))
            return "bluetooth";
        if (name === "nordvpn-tray-blue") // NordVPN's connected state
            return "vpn_lock";
        if (name.startsWith("nordvpn"))
            return "vpn_key_off";
        return "";
    }

    Behavior on color {
        ColorAnimation {
            duration: Metrics.animMedium
            easing.type: Easing.OutCubic
        }
    }

    Row {
        id: row
        spacing: 10
        anchors.centerIn: parent

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayDelegate
                required property var modelData
                width: 20
                height: 20
                opacity: 0
                scale: 0.6

                Component.onCompleted: {
                    opacity = 1;
                    scale = 1;
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Metrics.animMedium
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Metrics.animMedium
                        easing.type: Easing.OutBack
                    }
                }

                readonly property string glyph: root.glyphFor(modelData.icon)

                Text {
                    anchors.centerIn: parent
                    visible: trayDelegate.glyph !== ""
                    text: trayDelegate.glyph
                    font.family: Metrics.iconFont
                    font.pixelSize: Metrics.iconSize
                    color: Colors.text
                }

                Image {
                    anchors.fill: parent
                    visible: trayDelegate.glyph === ""
                    source: visible ? trayDelegate.modelData.icon : ""
                    sourceSize: Qt.size(width, height)
                    smooth: true
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: trayDelegate.modelData.activate()
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: trayDelegate.modelData.display(trayDelegate.Window.window, trayDelegate.x, trayDelegate.y + trayDelegate.height)
                }
            }
        }
    }
}
