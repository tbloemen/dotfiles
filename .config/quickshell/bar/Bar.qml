import QtQuick
import "Theme"
import "Modules"

Item {
    id: root
    property string screenName: ""

    // Distance from the network pill's right edge to the screen's right edge,
    // so the network card can unfold right under it. Plain x/width sums
    // rather than mapToItem, which a binding wouldn't re-evaluate.
    readonly property real networkAnchorRight: width - (rightRow.x + networkPill.x + networkPill.width)
    readonly property real mediaAnchorLeft: mediaPill.x

    Rectangle {
        anchors.fill: parent
        color: Colors.mantle
    }

    Workspaces {
        id: workspaces
        anchors.left: parent.left
        anchors.leftMargin: Metrics.gap / 2
        anchors.verticalCenter: parent.verticalCenter
        screenName: root.screenName
    }

    MediaIndicator {
        id: mediaPill
        anchors.left: workspaces.right
        anchors.leftMargin: Metrics.gap
        anchors.verticalCenter: parent.verticalCenter
        screenName: root.screenName
    }

    Clock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    Row {
        id: rightRow
        anchors.right: parent.right
        anchors.rightMargin: Metrics.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.gap
        layoutDirection: Qt.LeftToRight

        Tray {}
        DarkmanIndicator {}
        Memory {}
        IdleInhibitorButton {}
        NetworkIndicator {
            id: networkPill
            screenName: root.screenName
        }
        Volume {}
        Battery {}
        Notifications {
            screenName: root.screenName
        }
        PowerButton {
            screenName: root.screenName
        }
    }
}
