import QtQuick
import "Theme"
import "Modules"

Item {
    id: root
    property string screenName: ""

    Rectangle {
        anchors.fill: parent
        color: Colors.mantle
    }

    Workspaces {
        anchors.left: parent.left
        anchors.leftMargin: Metrics.gap / 2
        anchors.verticalCenter: parent.verticalCenter
        screenName: root.screenName
    }

    Clock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Metrics.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.gap
        layoutDirection: Qt.LeftToRight

        Tray {}
        HyprWhspr {}
        DarkmanIndicator {}
        Memory {}
        IdleInhibitorButton {}
        NetworkIndicator {}
        Volume {}
        Battery {}
        PowerButton {}
    }
}
