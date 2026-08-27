pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persists recent/most-used git repos — same FileView+JsonAdapter
// pattern as SshUsageService/AppUsageService, scoped to repo paths.
Singleton {
    id: root

    readonly property int maxRecent: 10

    property var recent: []        // [{path, timestamp}, ...], newest first
    property var usageCounts: ({}) // {path: count}

    property FileView _store: FileView {
        path: Quickshell.env("HOME") + "/.cache/nisfere/git_usage.json"
        blockLoading: true

        adapter: JsonAdapter {
            id: jsonAdapter
            property var recent: []
            property var usageCounts: ({})
        }

        onAdapterUpdated: writeAdapter()
        onLoaded: {
            root.recent = jsonAdapter.recent ?? [];
            root.usageCounts = jsonAdapter.usageCounts ?? ({});
        }
        onLoadFailed: {
            root.recent = [];
            root.usageCounts = ({});
        }
    }

    function _save() {
        jsonAdapter.recent = root.recent;
        jsonAdapter.usageCounts = root.usageCounts;
    }

    // Call whenever the git manager is actually opened for a repo —
    // updates recent (move-to-front, capped) and the usage counter.
    function recordOpen(path) {
        const filtered = root.recent.filter(r => r.path !== path);
        filtered.unshift({
            path: path,
            timestamp: Date.now()
        });
        root.recent = filtered.slice(0, maxRecent);

        const counts = Object.assign({}, root.usageCounts);
        counts[path] = (counts[path] ?? 0) + 1;
        root.usageCounts = counts;

        _save();
    }

    readonly property var recentPaths: root.recent.map(r => r.path)

    function usageCount(path) {
        return root.usageCounts[path] ?? 0;
    }
}
