pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../Theme"

// Which MPRIS player the media pill and card (../MediaCard.qml) show.
//
// `active` is a player picked in the card's switcher (until the card
// closes), else whichever is playing, else the one that played last, else
// the first one there is.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var playing: players.find(p => p.isPlaying) ?? null
    property var lastPlayed: null
    property var pinned: null

    readonly property var active: {
        if (pinned !== null && players.includes(pinned))
            return pinned;
        if (playing !== null)
            return playing;
        if (lastPlayed !== null && players.includes(lastPlayed))
            return lastPlayed;
        return players[0] ?? null;
    }

    readonly property bool cardOpen: UiState.mediaCardScreen !== ""

    onPlayingChanged: {
        if (playing !== null)
            lastPlayed = playing;
    }
    onCardOpenChanged: {
        if (!cardOpen)
            pinned = null;
    }

    function formatTime(seconds: real): string {
        if (!isFinite(seconds) || seconds < 0)
            return "0:00";
        const s = Math.floor(seconds);
        const h = Math.floor(s / 3600);
        const m = Math.floor(s % 3600 / 60);
        const ss = String(s % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + ss : m + ":" + ss;
    }

    // MPRIS doesn't push position updates; poll it while someone's looking.
    Timer {
        interval: 1000
        repeat: true
        running: root.cardOpen && root.active !== null && root.active.isPlaying
        onTriggered: root.active.positionChanged()
    }
}
