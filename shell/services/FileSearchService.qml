pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// File search via `find` — same Process + StdioCollector pattern.
// Plain QML Process rather than routed through the daemon: this is
// stateless, needs no privileges beyond the user's own session, and
// is already async on its own.
Singleton {
    id: root

    property var results: []   // [{ path, name, isDir }]
    property bool loading: false
    property string errorMessage: ""

    // Below this, don't search at all — short queries match nearly
    // everything in a home directory.
    readonly property int minQueryLength: 3

    // `find` doesn't have a native --limit. We pipe it through `head`
    // in the shell to keep the optimization of not parsing thousands
    // of lines in QML.
    readonly property int maxResults: 1000

    readonly property var _defaultFolders: ["Downloads", "Pictures", "Documents", "Projects", "Videos", "Music", "Desktop"]

    // Ranks (does not filter) the (already head-capped) result set:
    // exact filename match first, then non-hidden (no dotfolder in the
    // path) results, then results under one of the common top-level
    // folders above, alphabetical tie-break otherwise. Score computed
    // ONCE per item up front, not inside the sort comparator.
    function _rankResults(list, query) {
        const home = Quickshell.env("HOME");
        const lowerQuery = query.toLowerCase();

        function score(r) {
            let s = 0;
            if (r.name.toLowerCase() === lowerQuery)
                s += 1000;
            if (r.path.indexOf("/.") === -1)
                s += 100;
            for (const d of root._defaultFolders) {
                const base = home + "/" + d;
                if (r.path === base || r.path.startsWith(base + "/")) {
                    s += 10;
                    break;
                }
            }
            return s;
        }

        const decorated = list.map(item => ({
                    item: item,
                    score: score(item)
                }));
        decorated.sort((a, b) => {
            const diff = b.score - a.score;
            if (diff !== 0)
                return diff;
            return a.item.name.localeCompare(b.item.name);
        });
        return decorated.map(d => d.item);
    }

    // Which query the currently in-flight (or just-finished) process
    // invocation was actually for — the declarative onStreamFinished
    // below has no other way to know what was searched for, needed to
    // rank correctly (exact-match scoring needs the query text).
    property string _lastQuery: ""

    property Process _searchProc: Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "");
                const mapped = lines.map(line => {
                    // "%y:%p\n" from the command below — %y is the
                    // file type letter (d = directory, f = regular
                    // file, ...).
                    const sepIdx = line.indexOf(":");
                    const typeChar = line.substring(0, sepIdx);
                    const path = line.substring(sepIdx + 1);
                    return {
                        path: path,
                        name: path.substring(path.lastIndexOf("/") + 1),
                        isDir: typeChar === "d"
                    };
                });
                root.results = root._rankResults(mapped, root._lastQuery);
                root.loading = false;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    root.errorMessage = text.trim();
                    root.loading = false;
                }
            }
        }
    }

    function search(query) {
        if (query.trim().length < root.minQueryLength) {
            root.results = [];
            root.errorMessage = "";
            root.loading = false;
            return;
        }
        // Explicit stop-before-restart guards against overlapping
        // invocations if you type faster than it can respond.
        if (root._searchProc.running)
            root._searchProc.running = false;
        root.errorMessage = "";
        root.loading = true;
        root._lastQuery = query;
        // Using sh -c allows us to use pipe (|) for `head` and discard
        // permission denied errors (2>/dev/null).
        // We pass the arguments securely as $1 and $2 to prevent injection.
        // %y:%p (not just %p) so we can tell files from directories.
        root._searchProc.command = ["sh", "-c", "find ~/ -iname \"*$1*\" -printf '%y:%p\\n' 2>/dev/null | head -n \"$2\"", "find-search", query, root.maxResults.toString()];
        root._searchProc.running = true;
    }

    function openFile(path) {
        Quickshell.execDetached(["xdg-open", path]);
    }

    function openContainingFolder(path) {
        const dir = path.substring(0, path.lastIndexOf("/")) || "/";
        Quickshell.execDetached(["xdg-open", dir]);
    }
}
