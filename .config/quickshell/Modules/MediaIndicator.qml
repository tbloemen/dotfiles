import "../Theme"
import "../Services"

// Now-playing pill, only there while an MPRIS player is. Click opens the
// media card (../MediaCard.qml) on this bar's screen, right click
// plays/pauses; hover reveals the track.
Pill {
    id: root
    property string screenName: ""
    readonly property bool cardOpen: UiState.mediaCardScreen === screenName
    readonly property var player: Media.active
    readonly property string track: {
        if (player === null)
            return "";
        const t = [player.trackTitle, player.trackArtist].filter(s => s && s.length > 0).join(" — ");
        return t.length > 40 ? t.slice(0, 39) + "…" : t;
    }

    visible: player !== null
    bg: cardOpen ? Colors.red : Colors.flamingo
    fg: Colors.mantle
    icon: cardOpen ? "close" : player !== null && player.isPlaying ? "music_note" : "pause"
    label: track

    onClicked: {
        const open = cardOpen;
        UiState.closePanels();
        UiState.mediaCardScreen = open ? "" : screenName;
    }
    onRightClicked: {
        if (player !== null && player.canTogglePlaying)
            player.togglePlaying();
    }
}
