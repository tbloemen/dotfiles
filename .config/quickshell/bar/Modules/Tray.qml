import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../Theme"

// Replaces waybar's tray module. Icons fade+scale in as they register
// (animation idea #4) rather than the row just abruptly reflowing.
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: Metrics.pillHeight

    Row {
        id: row
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

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
                    NumberAnimation { duration: Metrics.animMedium }
                }
                Behavior on scale {
                    NumberAnimation { duration: Metrics.animMedium; easing.type: Easing.OutBack }
                }

                Image {
                    anchors.fill: parent
                    source: trayDelegate.modelData.icon
                    smooth: true
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: trayDelegate.modelData.activate()
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: trayDelegate.modelData.display(
                        trayDelegate.Window.window,
                        trayDelegate.x,
                        trayDelegate.y + trayDelegate.height
                    )
                }
            }
        }
    }
}
