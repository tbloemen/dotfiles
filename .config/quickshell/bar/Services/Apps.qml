pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The app launcher's model (../Launcher.qml), replacing rofi's drun mode:
// the desktop entries Quickshell already indexes, a small fuzzy matcher, and
// launch counts so the apps you use float to the top.
//
// Counts live in Quickshell's per-shell state dir (statePath), not in this
// repo, so they never show up in git.
Singleton {
    id: root

    readonly property var entries: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher.json")
        watchChanges: false
        printErrors: false
        onAdapterUpdated: writeAdapter()
        // First run: nothing on disk yet, start from empty counts.
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: usage
            property var counts: ({})
        }
    }

    function count(entry): int {
        return usage.counts[entry.id] ?? 0;
    }

    // Higher is better, 0 means no match. Name matches beat generic name /
    // keyword matches, which beat a match in the comment; within a field a
    // prefix beats a word start, which beats a substring, which beats a
    // scattered subsequence ("ffx" -> Firefox).
    function fieldScore(field: string, q: string): real {
        if (!field)
            return 0;
        const f = field.toLowerCase();
        if (f === q)
            return 100;
        if (f.startsWith(q))
            return 80;
        const i = f.indexOf(q);
        if (i > 0)
            return /[\s\-_.]/.test(f[i - 1]) ? 60 : 40;
        // Subsequence: every query char in order, rewarded for staying close
        // together.
        let pos = -1;
        let gaps = 0;
        for (let c = 0; c < q.length; c++) {
            const next = f.indexOf(q[c], pos + 1);
            if (next === -1)
                return 0;
            if (pos !== -1)
                gaps += next - pos - 1;
            pos = next;
        }
        return Math.max(1, 20 - gaps);
    }

    function score(entry, q: string): real {
        const name = fieldScore(entry.name, q);
        const generic = fieldScore(entry.genericName, q) * 0.7;
        const keywords = Math.max(0, ...entry.keywords.map(k => fieldScore(k, q))) * 0.6;
        // Comments are prose; only count a literal hit, not a subsequence.
        const comment = (entry.comment ?? "").toLowerCase().includes(q) ? 15 : 0;
        return Math.max(name, generic, keywords, comment);
    }

    // Matching entries, best first. An empty query lists everything by use,
    // then alphabetically.
    function search(query: string): var {
        const q = query.trim().toLowerCase();
        const byUse = (a, b) => count(b) - count(a) || a.name.localeCompare(b.name);
        if (q === "")
            return entries.slice().sort(byUse);
        return entries.map(e => ({
                    entry: e,
                    match: score(e, q)
                })).filter(r => r.match > 0).map(r => ({
                    entry: r.entry,
                    // Use only breaks near-ties; it shouldn't outrank a
                    // clearly better match.
                    score: r.match + Math.min(count(r.entry), 20) * 0.5
                })).sort((a, b) => b.score - a.score || byUse(a.entry, b.entry)).map(r => r.entry);
    }

    // Web search / URLs go to $BROWSER, which hyprland.lua sets (and
    // overrides /etc/environment's value with).
    readonly property string browser: Quickshell.env("BROWSER") || "xdg-open"
    // Its desktop entry, for the name and icon. $BROWSER is a command, which
    // need not match the entry's id or Exec (zen-browser is zen.desktop,
    // running /opt/zen-browser-bin/zen-bin), so also try the icon name.
    readonly property var browserEntry: {
        const bin = browser.split(" ")[0].split("/").pop();
        return entries.find(e => e.id === bin || e.icon === bin || (e.command[0] ?? "").split("/").pop() === bin) ?? DesktopEntries.heuristicLookup(bin);
    }
    // Firefox-family browsers can search with whatever engine you picked
    // in them; others get a DuckDuckGo URL.
    readonly property bool browserSearches: /firefox|zen|librewolf|floorp|waterfox/i.test(browser)

    // "example.com", "localhost:3000/x", "https://…" -- something to open
    // rather than search for.
    function asUrl(query: string): string {
        const q = query.trim();
        if (/^https?:\/\/\S+$/i.test(q))
            return q;
        if (/^(localhost|[\w-]+(\.[\w-]+)*\.[a-z]{2,})(:\d+)?(\/\S*)?$/i.test(q))
            return "https://" + q;
        return "";
    }

    function openWeb(query: string) {
        const url = asUrl(query);
        const cmd = browser.split(" ").filter(s => s.length > 0);
        if (url !== "")
            Quickshell.execDetached(cmd.concat([url]));
        else if (browserSearches)
            Quickshell.execDetached(cmd.concat(["--search", query.trim()]));
        else
            Quickshell.execDetached(cmd.concat(["https://duckduckgo.com/?q=" + encodeURIComponent(query.trim())]));
    }

    function launch(entry) {
        const counts = Object.assign({}, usage.counts);
        counts[entry.id] = (counts[entry.id] ?? 0) + 1;
        usage.counts = counts;

        // DesktopEntry.execute() ignores Terminal=true, so wrap those ourselves.
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["ghostty", "-e", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            entry.execute();
    }
}
