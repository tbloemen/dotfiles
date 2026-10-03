import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "Theme"
import "Services"

// App launcher, replacing `rofi -show drun` on SUPER+SPACE. A search field
// over the desktop entries from Services/Apps.qml, ranked by match and by how
// often you launch each app.
//
// Same window/focus setup as PowerMenu.qml (see there on why it's a
// HyprlandFocusGrab and not exclusive keyboard focus): one per screen, open
// when its name is in UiState.launcherScreen, outside click or Esc closes.
// Unlike the cards it isn't tied to a pill, so it drops in centered under
// the bar instead of unfolding from a corner.
//
// Typing a calculation ("2^10", "sqrt(2)*3") puts its result on top
// (Services/Calc.qml); Enter on it copies the result.
//
// Rows are plain items -- {kind, title, subtitle, icon, glyph, ...} -- so
// apps and calculator results share one list and one delegate.
//
// Keys: type to filter, ↑↓ / Tab / Ctrl+j k n p move, Enter launches.
PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property var modelData
    required property PanelWindow barWindow
    screen: modelData

    readonly property bool open: UiState.launcherScreen === modelData.name
    property real progress: 0 // 0 closed .. 1 open, drives the card transition

    readonly property int rowHeight: 44
    readonly property int maxRows: 8
    readonly property var results: {
        const items = [];
        const calc = Calc.evaluate(search.text);
        if (calc !== null)
            items.push({
                kind: "calc",
                title: "= " + calc.text,
                subtitle: calc.expr + "  ·  Enter copies the result",
                icon: "",
                glyph: "calculate",
                value: calc.text
            });
        for (const e of Apps.search(search.text))
            items.push({
                kind: "app",
                title: e.name,
                subtitle: e.genericName || e.comment || "",
                icon: e.icon ? Quickshell.iconPath(e.icon, true) : "",
                glyph: "apps",
                entry: e
            });
        return items;
    }

    function close() {
        UiState.launcherScreen = "";
    }

    function launch(item) {
        if (!item)
            return;
        if (item.kind === "calc")
            Quickshell.execDetached(["wl-copy", "--", item.value]);
        else
            Apps.launch(item.entry);
        close();
    }

    function move(delta) {
        if (list.count === 0)
            return;
        list.currentIndex = (list.currentIndex + delta + list.count) % list.count;
    }

    onOpenChanged: {
        if (open) {
            closeAnim.stop();
            search.text = "";
            list.currentIndex = 0;
            list.positionViewAtBeginning();
            search.forceActiveFocus();
            openAnim.restart();
        } else {
            openAnim.stop();
            closeAnim.restart();
        }
    }

    // A new query starts back at the best match.
    onResultsChanged: list.currentIndex = 0

    NumberAnimation {
        id: openAnim
        target: root
        property: "progress"
        to: 1
        duration: 300
        easing.type: Easing.OutExpo
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "progress"
        to: 0
        duration: 150
        easing.type: Easing.InCubic
    }

    visible: open || progress > 0
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        windows: [root, root.barWindow]
        active: root.open
        onCleared: root.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.crust
        opacity: 0.25 * root.progress

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: root.close()
        }
    }

    Item {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(parent.height * 0.12) - 12 * (1 - root.progress)
        width: 560
        height: column.implicitHeight + 12

        transformOrigin: Item.Top
        scale: 0.96 + 0.04 * root.progress
        opacity: root.progress

        // Shadow on a background of its own, see PowerMenu.qml.
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Colors.base
            border.width: 1
            border.color: Colors.surface1
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, Colors.mode === "light" ? 0.18 : 0.45)
                shadowBlur: 0.9
                shadowVerticalOffset: 4
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6

            Item {
                width: parent.width
                height: 40

                Text {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "search"
                    font.family: Metrics.iconFont
                    font.pixelSize: 20
                    color: Colors.lavender
                }

                TextInput {
                    id: search
                    anchors.left: searchIcon.right
                    anchors.right: countText.left
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    font.family: Metrics.uiFont
                    font.pixelSize: 15
                    color: Colors.text
                    selectionColor: Colors.surface1
                    selectedTextColor: Colors.text

                    onAccepted: root.launch(root.results[list.currentIndex])

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        if (event.key === Qt.Key_Escape)
                            root.close();
                        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))
                            root.move(1);
                        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))
                            root.move(-1);
                        else if (event.key === Qt.Key_PageDown)
                            root.move(Math.min(root.maxRows, list.count - 1 - list.currentIndex));
                        else if (event.key === Qt.Key_PageUp)
                            root.move(-Math.min(root.maxRows, list.currentIndex));
                        else
                            return;
                        event.accepted = true;
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text.length === 0
                        text: "Search apps"
                        font: search.font
                        color: Colors.overlay0
                    }
                }

                Text {
                    id: countText
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: list.count
                    font.family: Metrics.uiFont
                    font.pixelSize: 11
                    color: Colors.overlay0
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Colors.surface1
            }

            Item {
                width: parent.width
                height: 6
            }

            ListView {
                id: list
                width: parent.width
                height: Math.max(1, Math.min(count, root.maxRows)) * root.rowHeight
                clip: true
                model: root.results
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: Metrics.animMedium
                highlightMoveVelocity: -1
                // Keep the highlight in view without centering it.
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: height

                highlight: Rectangle {
                    radius: 6
                    color: Qt.rgba(Colors.surface1.r, Colors.surface1.g, Colors.surface1.b, 0.5)
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem

                    width: list.width
                    height: root.rowHeight

                    // Same whole-pixel slide as the power menu rows.
                    property real slide: current ? 3 : 0
                    Behavior on slide {
                        NumberAnimation {
                            duration: Metrics.animMedium
                            easing.type: Easing.OutCubic
                        }
                    }

                    Item {
                        anchors.fill: parent
                        transform: Translate {
                            x: row.slide
                        }

                        Item {
                            id: iconBox
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            height: 28

                            Image {
                                id: appIcon
                                anchors.fill: parent
                                source: row.modelData.icon
                                sourceSize.width: 56
                                sourceSize.height: 56
                                asynchronous: true
                                smooth: true
                                mipmap: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: appIcon.status !== Image.Ready
                                text: row.modelData.glyph
                                font.family: Metrics.iconFont
                                font.pixelSize: 22
                                color: row.modelData.kind === "calc" ? Colors.lavender : Colors.overlay0
                            }
                        }

                        Column {
                            anchors.left: iconBox.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: row.modelData.title
                                font.family: Metrics.uiFont
                                font.pixelSize: Metrics.textSize
                                font.bold: row.modelData.kind === "calc"
                                color: Colors.text
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                elide: Text.ElideRight
                                text: row.modelData.subtitle
                                font.family: Metrics.uiFont
                                font.pixelSize: 11
                                color: row.current ? Colors.subtext0 : Colors.overlay0
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = row.index
                        onClicked: root.launch(row.modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "No matches"
                    font.family: Metrics.uiFont
                    font.pixelSize: 12
                    color: Colors.overlay0
                }
            }
        }
    }
}
