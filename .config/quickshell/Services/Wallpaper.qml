pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Theme"

// Which wallpaper frames to show, for the desktop (../WallpaperWindow.qml)
// and the lock screen (../LockSurface.qml), both through ../WallpaperView.qml.
// Replaces hyprpaper and its darkman hook.
//
// ~/wallpapers/active is a symlink to a wallpapers/<name>/ directory. With a
// wallpaper.json (written from a macOS dynamic .heic by
// scripts/wallpaper-import.py) it's a set of frames, each placed by the sun's
// elevation and whether it's rising; the wallpaper follows the real sun at
// darkman's lat/lng, blending between the two frames around it. Without one
// it's the old light.png + dark.png pair, picked by Colors.mode.
//
// Darkman stays in charge of the mode. While its mode agrees with the sun the
// frames follow the sun; after a manual `darkman toggle` they don't, and the
// wallpaper holds the frame of that mode nearest to now until darkman's next
// switch at sunrise/sunset brings the two back in line.
//
// After repointing the symlink (`ln -sfn other-wallpaper active` in
// ~/wallpapers), run `qs ipc call wallpaper reload`. `qs ipc call wallpaper
// preview 18:30` pins the clock to scrub through a day (`preview ""` undoes
// it); `status` shows what's picked and why.
Singleton {
    id: root

    // Where darkman flips (sun's centre at the horizon, with refraction), and
    // how far either side of it a disagreeing mode is still darkman's own
    // switch landing a little before or after ours rather than a manual
    // override.
    readonly property real horizon: -0.833
    readonly property real overrideMargin: 2

    readonly property string dir: Quickshell.env("HOME") + "/wallpapers/active/"

    // Bumped by reload(); a different URL makes every Image load afresh
    // even though the path itself didn't change.
    property int revision: 0

    property real lat: 52
    property real lng: 4.4
    // [{file, mode, elevation?, rising?}]; no elevations = light/dark only.
    property var frames: []
    // The sun's range the frame elevations were measured against (an equinox
    // at darkman's latitude, for clock-time sets); 0 = take them as they are.
    property real dayMin: 0
    property real dayMax: 0
    // Minutes since midnight to pretend it is, or -1 for the real time.
    property int previewMinutes: -1

    // What WallpaperView draws: `lower`, with `upper` at `blend` over it.
    property string lower: ""
    property string upper: ""
    property real blend: 0
    property string status: ""

    function url(file: string): string {
        return file ? "file://" + dir + file + (revision > 0 ? "?" + revision : "") : "";
    }

    function reload() {
        revision++;
        manifest.reload();
    }

    function preview(time: string): string {
        const m = /^(\d{1,2}):(\d{2})$/.exec(time.trim());
        previewMinutes = m ? Number(m[1]) * 60 + Number(m[2]) : -1;
        update();
        return status;
    }

    // Low-precision solar position (the Astronomical Almanac's, good to a
    // fraction of a degree, plenty for picking frames). Elevations in degrees.
    function sun(date: date): var {
        const rad = Math.PI / 180;
        const d = date.getTime() / 86400000 - 10957.5; // days since J2000
        const g = (357.529 + 0.98560028 * d) * rad;
        const q = 280.459 + 0.98564736 * d;
        const l = (q + 1.915 * Math.sin(g) + 0.020 * Math.sin(2 * g)) * rad;
        const e = (23.439 - 0.00000036 * d) * rad;
        const ra = Math.atan2(Math.cos(e) * Math.sin(l), Math.cos(l)) / rad;
        const decl = Math.asin(Math.sin(e) * Math.sin(l)) / rad;
        const gmst = 18.697374558 + 24.06570982441908 * d; // hours
        let h = ((gmst * 15 + lng - ra) % 360 + 360) % 360;
        if (h > 180)
            h -= 360;
        const el = Math.asin(Math.sin(lat * rad) * Math.sin(decl * rad) + Math.cos(lat * rad) * Math.cos(decl * rad) * Math.cos(h * rad)) / rad;
        return {
            elevation: el,
            rising: h < 0,
            // Today's lowest (solar midnight) and highest (solar noon).
            min: Math.abs(lat + decl) < 90 ? -(90 - Math.abs(lat + decl)) : -90,
            max: 90 - Math.abs(lat - decl)
        };
    }

    // Where in today's cycle the sun at `elevation` is: 0 at solar midnight,
    // 0.5 at noon, rising in between and setting after. Elevations today
    // never reaches clamp to noon or midnight, so a midsummer-noon frame
    // still shows at a winter noon.
    function phase(s: var, elevation: real, rising: bool): real {
        const f = Math.max(0, Math.min(1, (elevation - s.min) / (s.max - s.min)));
        return rising ? f / 2 : 1 - f / 2;
    }

    // How far (0..1) the sun is from frame `a` to frame `b`, by elevation
    // rather than time: the light follows the sun's height. When noon or
    // midnight lies between the two, `a` holds until the sun has turned and
    // the blend runs over the way back -- so with a morning frame at 9 deg and
    // a sunset one at 0, the day frame stays up until the sun sinks back to
    // 9 deg, rather than being half sunset by midday.
    function progress(s: var, a: var, b: var, p: real, pa: real, pb: real): real {
        const clamp = x => Math.max(s.min, Math.min(s.max, x));
        // Measured in how much the sky changes rather than raw degrees: a
        // degree of twilight counts several times a degree of deep night
        // or high sun, so a midnight-to-morning blend happens at dawn
        // instead of evenly through the night.
        const sky = el => el + 30 * Math.tanh((el + 4) / 5);
        const frac = (from, to) => from === to ? 1 : Math.max(0, Math.min(1, (sky(s.elevation) - sky(from)) / (sky(to) - sky(from))));
        const from = clamp(a.elevation);
        const to = clamp(b.elevation);
        if (a.rising === b.rising) {
            // Same side of noon: monotone, unless the gap wraps all the way
            // round, which only time can measure.
            if ((a.rising ? to >= from : to <= from) && pb >= pa)
                return frac(from, to);
            const gap = ((pb - pa) % 1 + 1) % 1;
            return gap > 0 ? (((p - pa) % 1 + 1) % 1) / gap : 0;
        }
        if (s.rising === a.rising)
            return 0; // not past the turn yet
        // Past noon (a rising, b setting) the sun comes down from the top;
        // past midnight it climbs from the bottom.
        if (a.rising)
            return frac(from >= to ? from : s.max, to);
        return frac(from <= to ? from : s.min, to);
    }

    // A frame's elevation moved into today's range. Above the horizon it
    // scales with today's noon, so an equinox 11:00 frame still sits below
    // the 13:00 one on a winter day whose noon is lower than either. Below
    // -12 deg (past nautical dusk) the night stretches between there and
    // today's midnight the same way; twilight itself stays absolute, since
    // how the sky looks at -6 deg doesn't depend on the season.
    function scaled(s: var, el: real): real {
        const deep = -12;
        if (el > 0 && dayMax > 0)
            return el * s.max / dayMax;
        if (el < deep && dayMin < deep)
            return deep + (el - deep) * (Math.min(s.min, deep - 0.1) - deep) / (dayMin - deep);
        return el;
    }

    function update() {
        let now = new Date();
        if (previewMinutes >= 0)
            now = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, previewMinutes);
        const mode = Colors.mode;

        if (frames.length === 0) {
            set(url(mode + ".png"), "", 0, `light/dark pair, ${mode}`);
            return;
        }
        const s = sun(now);
        const timed = frames.filter(f => f.elevation !== undefined).map(f => Object.assign({}, f, {
                        elevation: scaled(s, f.elevation)
                    }));
        if (timed.length === 0) {
            const f = frames.find(f => f.mode === mode) ?? frames[0];
            set(url(f.file), "", 0, `untimed set, ${mode}: ${f.file}`);
            return;
        }

        const p = phase(s, s.elevation, s.rising);
        const keyed = timed.map((f, i) => ({
                    file: f.file,
                    mode: f.mode,
                    phase: phase(s, f.elevation, f.rising),
                    i: i
                })).sort((a, b) => a.phase - b.phase || a.i - b.i);
        const where = `sun ${s.elevation.toFixed(1)}° ${s.rising ? "rising" : "setting"} (${now.toTimeString().slice(0, 5)}), phase ${p.toFixed(3)}`;

        const sunMode = s.elevation > horizon + overrideMargin ? "light" : s.elevation < horizon - overrideMargin ? "dark" : mode;
        // A preview shows the day as darkman would run it, without overrides.
        if (sunMode !== mode && previewMinutes < 0) {
            const dist = k => Math.min(Math.abs(k.phase - p), 1 - Math.abs(k.phase - p));
            const pick = keyed.filter(k => k.mode === mode).sort((a, b) => dist(a) - dist(b))[0];
            if (pick) {
                set(url(pick.file), "", 0, `${where}; darkman says ${mode} -> holding ${pick.file}`);
                return;
            }
        }

        // The last frame at or before now, wrapping round midnight, and the
        // one after it.
        let li = keyed.length - 1;
        for (let i = 0; i < keyed.length; i++)
            if (keyed[i].phase <= p)
                li = i;
        const lo = keyed[li];
        const hi = keyed[(li + 1) % keyed.length];
        const t = progress(s, timed[lo.i], timed[hi.i], p, lo.phase, hi.phase);
        // Ease in and out, so each frame holds for a while around its own
        // moment instead of being half of something else most of the time.
        const b = t * t * (3 - 2 * t);
        set(url(lo.file), url(hi.file), b, `${where}; ${lo.file} -> ${hi.file} at ${b.toFixed(3)}`);
    }

    function set(lo: string, hi: string, b: real, why: string) {
        // Same image either side (the set reuses a frame) is no blend at all.
        if (hi === lo || b <= 0.001) {
            hi = "";
            b = 0;
        } else if (b >= 0.999) {
            lo = hi;
            hi = "";
            b = 0;
        }
        lower = lo;
        upper = hi;
        blend = b;
        status = why;
    }

    Connections {
        target: Colors
        function onModeChanged() {
            root.update();
        }
    }

    // The sun moves about a degree every 4 minutes at most; a minute keeps
    // each step well under what you'd notice.
    Timer {
        running: true
        repeat: true
        interval: 60 * 1000
        onTriggered: root.update()
    }

    FileView {
        id: manifest
        path: root.dir + "wallpaper.json"
        printErrors: false
        watchChanges: false
        onLoaded: {
            try {
                const m = JSON.parse(text());
                root.dayMin = m.dayMin ?? 0;
                root.dayMax = m.dayMax ?? 0;
                root.frames = m.frames ?? [];
            } catch (e) {
                console.warn("wallpaper.json:", e);
                root.frames = [];
            }
            root.update();
        }
        onLoadFailed: {
            root.dayMin = root.dayMax = 0;
            root.frames = [];
            root.update();
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/darkman/config.yaml"
        printErrors: false
        watchChanges: false
        onLoaded: {
            const t = text();
            const la = /^lat:\s*(-?[\d.]+)/m.exec(t);
            const ln = /^lng:\s*(-?[\d.]+)/m.exec(t);
            if (la)
                root.lat = Number(la[1]);
            if (ln)
                root.lng = Number(ln[1]);
            root.update();
        }
    }
}
