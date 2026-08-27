pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persists recent/most-used docker entries — same FileView+JsonAdapter
// pattern as SshUsageService/GitUsageService. Generic string keys
// rather than a dedicated "repo"/"alias" field, since this tracks TWO
// different kinds of things (compose projects and individual
// containers) in one store — callers prefix their own keys
// ("compose:<name>" / "container:<name>") to keep the two namespaces
// from colliding.
Singleton {
    id: root

    readonly property int maxRecent: 10

    property var recent: []        // [{key, timestamp}, ...], newest first
    property var usageCounts: ({}) // {key: count}

    property FileView _store: FileView {
        path: Quickshell.env("HOME") + "/.cache/nisfere/docker_usage.json"
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

    // Call whenever an action is actually taken against a key (not on
    // mere display) — updates recent (move-to-front, capped) and the
    // usage counter.
    function recordUse(key) {
        const filtered = root.recent.filter(r => r.key !== key);
        filtered.unshift({
            key: key,
            timestamp: Date.now()
        });
        root.recent = filtered.slice(0, maxRecent);

        const counts = Object.assign({}, root.usageCounts);
        counts[key] = (counts[key] ?? 0) + 1;
        root.usageCounts = counts;

        _save();
    }

    readonly property var recentKeys: root.recent.map(r => r.key)

    function usageCount(key) {
        return root.usageCounts[key] ?? 0;
    }
}
