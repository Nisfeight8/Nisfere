pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Shared wrapper around Quickshell's DesktopEntries singleton:
//   1. Warm-up — touches DesktopEntries.applications once at shell
//      startup (Component.onCompleted), so the underlying .desktop file
//      scan/parse has already happened well before anything actually
//      needs it (e.g. before Overview's first open, which was
//      previously the first thing to trigger it, contributing to the
//      first-open icon-loading burst).
//   2. Memoized lookup — WorkspaceButton, OverviewWindow, and
//      SystemMonitorTool all independently call
//      DesktopEntries.heuristicLookup() for the same app classes.
//      Caching by class/appId avoids redoing that matching work
//      repeatedly across components.
//   3. toResultRow() — the single canonical mapping from a
//      DesktopEntry to the {id,title,subtitle,thumbnail,actions,action}
//      shape SearchResultRow expects. Used by both SearchProviders'
//      "apps" provider search() and AppLauncherPanel's browse-mode
//      list, so there's exactly one place that decides what an app
//      result row looks like (subtitle, favorite-star action, launch
//      behavior) instead of two independently-maintained copies.
Singleton {
    id: root

    property var _cache: ({})   // classOrName -> DesktopEntry | null

    function lookup(classOrName) {
        const key = classOrName ?? "";
        if (key === "")
            return null;
        if (root._cache.hasOwnProperty(key)) {
            return root._cache[key];
        }
        const entry = DesktopEntries.heuristicLookup(key);
        // Mutate in place — do NOT reassign root._cache to a new object.
        // This function runs as part of evaluating property bindings
        // (e.g. OverviewWindow's _iconName), which read _cache. A
        // reassignment fires _cache's changed() signal, which
        // re-triggers evaluation of whatever binding is CURRENTLY
        // running mid-flight — a binding loop, evaluating itself while
        // still evaluating. Mutating the existing object's contents
        // doesn't touch the property reference itself, so no change
        // notification fires at all.
        root._cache[key] = entry ?? null;
        return entry ?? null;
    }

    // Convenience — the common case is "give me an icon name for this
    // class/appId, or a fallback if nothing matched".
    function iconFor(classOrName, fallback) {
        const entry = root.lookup(classOrName);
        return (entry && entry.icon) ? entry.icon : (fallback ?? "");
    }

    property var _pathCache: ({})

    // Quickshell.iconPath() resolves an icon NAME to an actual file
    // path via theme lookup — also worth memoizing, since many
    // components (LauncherAppsPanel, OverviewWindow, WorkspaceButton)
    // request the SAME icon names repeatedly.
    function resolveIconPath(iconName) {
        const key = iconName ?? "";
        if (key === "")
            return "";
        if (root._pathCache.hasOwnProperty(key)) {
            return root._pathCache[key];
        }
        const path = Quickshell.iconPath(key);
        // Mutate in place — same reasoning as _cache above, avoids a
        // binding-loop risk if this is ever called from inside a
        // property binding.
        root._pathCache[key] = path;
        return path;
    }

    // DesktopEntry -> SearchResultRow shape. `thumbnail` (not `icon`)
    // is used deliberately — apps have real icon file paths, not
    // Lucide icon names, and SearchResultRow renders `thumbnail` via
    // an actual rounded Image instead of a LucideIcon.
    function toResultRow(app) {
        return {
            id: "app-" + app.name,
            title: app.name,
            subtitle: (app.categories || [])[0] || "",
            thumbnail: root.resolveIconPath(app.icon),
            actions: [
                {
                    icon: AppUsageService.isFavorite(app.name) ? "star" : "star-off",
                    trigger: () => AppUsageService.toggleFavorite(app.name)
                }
            ],
            action: () => {
                app.execute();
                AppUsageService.recordLaunch(app.name);
            }
        };
    }

    Component.onCompleted: {
        // Just touching .values triggers Quickshell's own internal scan
        // if it hasn't happened yet — we don't need the result here.
        DesktopEntries.applications.values;
    }
}
