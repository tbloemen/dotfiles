pragma Singleton
import Quickshell

// Tiny shared UI state that needs to stay in sync across monitors (Variants
// instantiates one PanelWindow + IdleInhibitor per screen; the idle-inhibit
// toggle is a single global concept, not a per-monitor one).
Singleton {
    property bool idleInhibited: false
}
