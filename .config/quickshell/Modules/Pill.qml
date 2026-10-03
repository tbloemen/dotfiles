import QtQuick
import "../Theme"

// Shared module chrome: a rounded, colored pill holding an icon glyph and an
// optional label that only reveals on hover (animation idea #2 — hover-expand
// modules). Mirrors waybar's style.css pill styling (radius 4-6px, colored
// per-module background) but the width/color changes actually animate instead
// of snapping.
Item {
    id: root

    property alias icon: iconText.text
    property string value: "" // always visible, e.g. a percentage
    property string label: "" // only revealed on hover (animation idea #2)
    property color bg: Colors.base
    property color fg: Colors.mantle
    property bool forceExpanded: false
    readonly property bool expanded: forceExpanded || hoverHandler.hovered

    signal clicked
    signal rightClicked
    signal wheel(real delta)

    implicitHeight: Metrics.pillHeight
    implicitWidth: row.implicitWidth + Metrics.paddingH * 2

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Metrics.animFast
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Metrics.radius
        color: root.bg
        layer.enabled: true
        layer.effect: PillShadow {}
        Behavior on color {
            ColorAnimation {
                duration: Metrics.animMedium
                easing.type: Easing.OutCubic
            }
        }
    }

    // While the pill's width animates the row is already at its new size, so
    // keep it pinned to the left edge and clipped to the pill: centered and
    // unclipped, the revealed label spilled out over the neighbouring
    // pills (e.g. the media pill's track over the workspaces).
    Item {
        anchors.fill: parent
        anchors.leftMargin: Metrics.paddingH
        anchors.rightMargin: Metrics.paddingH
        clip: true

        Row {
            id: row
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                id: iconText
                anchors.verticalCenter: parent.verticalCenter
                font.family: Metrics.iconFont
                font.pixelSize: Metrics.iconSize
                color: root.fg
            }

            Text {
                text: root.value
                visible: root.value.length > 0
                anchors.verticalCenter: parent.verticalCenter
                color: root.fg
                font.family: Metrics.uiFont
                font.pixelSize: Metrics.textSize
            }

            Text {
                text: root.label
                visible: root.label.length > 0 && root.expanded
                opacity: visible ? 1 : 0
                anchors.verticalCenter: parent.verticalCenter
                color: root.fg
                font.family: Metrics.uiFont
                font.pixelSize: Metrics.textSize

                Behavior on opacity {
                    NumberAnimation {
                        duration: Metrics.animFast
                    }
                }
            }
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.clicked()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.rightClicked()
    }

    WheelHandler {
        onWheel: event => root.wheel(event.angleDelta.y)
    }
}
