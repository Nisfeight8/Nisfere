pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persists recent/most-used SSH connections — same FileView+JsonAdapter
// pattern as AppUsageService, just scoped to SSH aliases instead of
// app names.
Singleton {
    id: root

    readonly property int maxRecent: 10

    property var recent: []        // [{alias, timestamp}, ...], newest first
    property var usageCounts: ({}) // {alias: count}

    property FileView _store: FileView {
        path: Quickshell.env("HOME") + "/.cache/nisfere/ssh_usage.json"
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

    // Call whenever a connection is actually made — updates recent
    // (move-to-front, capped) and the usage counter, same shape as
    // AppUsageService.recordLaunch.
    function recordConnect(alias) {
        const filtered = root.recent.filter(r => r.alias !== alias);
        filtered.unshift({
            alias: alias,
            timestamp: Date.now()
        });
        root.recent = filtered.slice(0, maxRecent);

        const counts = Object.assign({}, root.usageCounts);
        counts[alias] = (counts[alias] ?? 0) + 1;
        root.usageCounts = counts;

        _save();
    }

    readonly property var recentAliases: root.recent.map(r => r.alias)

    function usageCount(alias) {
        return root.usageCounts[alias] ?? 0;
    }
}
