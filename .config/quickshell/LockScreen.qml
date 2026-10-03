import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

// Lock screen, replacing hyprlock. hypridle's lock_cmd runs
// `qs ipc call lock lock` (shell.qml), so everything that locks through
// logind -- the idle timeout, before_sleep_cmd, the power menu -- lands here.
//
// The ext-session-lock protocol keeps the session locked even if this
// process dies; hyprland.lua sets misc:allow_session_lock_restore so a fresh
// locker (a restarted qs, or hyprlock from a TTY) can take the lock over
// instead of being stuck on Hyprland's "lockscreen died" screen. Quickshell
// itself keeps the lock across config reloads.
//
// One instance for all screens: WlSessionLock creates a LockSurface per
// monitor, and they all share the password and status below, so you can type
// on whichever monitor has focus and every screen shows the same dots.
//
// Authentication goes through the stock "login" PAM service (the same stack
// /etc/pam.d/hyprlock includes), so pam_faillock applies: after a few wrong
// passwords the account is locked for a while, and PAM's message says so.
Scope {
    id: root

    property string password: ""
    property bool authenticating: false
    property bool unlocking: false // fading out, unlock follows
    property string message: ""
    property int failures: 0

    signal failed // a wrong password; the surfaces shake

    readonly property bool locked: lock.locked

    function lock() {
        if (lock.locked)
            return;
        password = "";
        message = "";
        failures = 0;
        authenticating = false;
        unlocking = false;
        lock.locked = true;
    }

    function submit() {
        if (authenticating || unlocking || password === "")
            return;
        message = "";
        authenticating = true;
        if (!pam.start())
            fail("Couldn't start authentication");
    }

    function fail(text) {
        authenticating = false;
        password = "";
        failures++;
        message = text;
        failed();
    }

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            // What shows for a split second before the content is drawn.
            color: "black"

            LockSurface {
                anchors.fill: parent
                context: root
            }
        }
    }

    PamContext {
        id: pam

        // Hand over the typed password whenever PAM prompts for something.
        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.password);
        }

        // Informational/error text, e.g. pam_faillock's lockout notice. The
        // prompt itself ("Password: ") is not worth showing.
        onPamMessage: {
            if (!responseRequired && message !== "")
                root.message = message;
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.authenticating = false;
                root.password = "";
                root.unlocking = true;
                unlockDelay.restart();
            } else if (result === PamResult.MaxTries) {
                root.fail("Too many attempts");
            } else {
                // Keep a faillock notice from onPamMessage if there was one.
                root.fail(root.message !== "" ? root.message : "Wrong password");
            }
        }

        onError: err => root.fail("Authentication error: " + PamError.toString(err))
    }

    // Let the surfaces fade out before the compositor drops them.
    Timer {
        id: unlockDelay
        interval: 220
        onTriggered: {
            lock.locked = false;
            root.unlocking = false;
        }
    }
}
