pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persists favorites/recent/most-used app data for the App Launcher —
// same FileView+JsonAdapter pattern as TasksService.
Singleton {
    id: root

    readonly property int maxRecent: 10
    readonly property int maxMostUsed: 8

    property var favorites:    []   // [appName, ...]
    property var recent:       []   // [{name, timestamp}, ...], newest first
    property var usageCounts: ({})  // {appName: count}

    property FileView _store: FileView {
        path: Quickshell.env("HOME") + "/.cache/nisfere/app_usage.json"
        blockLoading: true

        adapter: JsonAdapter {
            id: jsonAdapter
            property var favorites: []
            property var recent: []
            property var usageCounts: ({})
        }

        onAdapterUpdated: writeAdapter()
        onLoaded: {
            root.favorites    = jsonAdapter.favorites    ?? [];
            root.recent       = jsonAdapter.recent       ?? [];
            root.usageCounts  = jsonAdapter.usageCounts  ?? ({});
        }
        onLoadFailed: {
            root.favorites   = [];
            root.recent      = [];
            root.usageCounts = ({});
        }
    }

    function _save() {
        jsonAdapter.favorites   = root.favorites;
        jsonAdapter.recent      = root.recent;
        jsonAdapter.usageCounts = root.usageCounts;
    }

    function isFavorite(name) {
        return root.favorites.indexOf(name) !== -1;
    }

    function toggleFavorite(name) {
        root.favorites = isFavorite(name)
            ? root.favorites.filter(n => n !== name)
            : [...root.favorites, name];
        _save();
    }

    // Call whenever an app is actually launched — updates both the
    // "recently used" list (move-to-front, capped) and the usage
    // counter (for "most used").
    function recordLaunch(name) {
        const filtered = root.recent.filter(r => r.name !== name);
        filtered.unshift({ name: name, timestamp: Date.now() });
        root.recent = filtered.slice(0, maxRecent);

        const counts = Object.assign({}, root.usageCounts);
        counts[name] = (counts[name] ?? 0) + 1;
        root.usageCounts = counts;

        _save();
    }

    readonly property var recentNames: root.recent.map(r => r.name)

    readonly property var mostUsedNames: {
        const entries = Object.entries(root.usageCounts);
        entries.sort((a, b) => b[1] - a[1]);
        return entries.slice(0, maxMostUsed).map(e => e[0]);
    }
}
