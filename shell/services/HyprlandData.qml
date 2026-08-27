pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // ── 1. NATIVE API (Fast, no delays, contains everything except x, y, w, h)
    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors
    readonly property bool usingLua: Hyprland.usingLua
    readonly property var focusedMonitor: Hyprland.focusedMonitor

    // Build workspaceIds directly from the native API (no Process needed!)
    readonly property var workspaceIds: {
        let ids = [];
        for (let i = 0; i < workspaces.values.length; i++) {
            let id = workspaces.values[i].id;
            if (id >= 1 && id <= 100)
                ids.push(id);
        }
        return ids.sort((a, b) => a - b);
    }

    // ── 2. JSON DATA (Only for windows, to get "at" and "size" in the Overview)
    property var windowList: []
    property var windowByAddress: ({})
    property var addresses: []

    property int debounceMs: 60
    property bool pendingWindows: false
    property int bootRetryCount: 0

    // Call this function only when there's a window change
    function scheduleClientsUpdate() {
        pendingWindows = true;
        debounceTimer.restart();
    }

    Timer {
        id: debounceTimer
        interval: root.debounceMs
        repeat: false
        onTriggered: {
            if (pendingWindows) {
                pendingWindows = false;
                // Disable and enable to guarantee execution
                getClients.running = false;
                getClients.running = true;
                getMonitorsSpecial.running = false;
                getMonitorsSpecial.running = true;
            }
        }
    }

    // ── 3. BOOT / SYNCHRONIZATION WITH LUA SCRIPT ───────────────────────
    Timer {
        id: bootSyncTimer
        interval: 400
        repeat: true
        running: true
        onTriggered: {
            bootRetryCount++;

            // Force the native API to see the Lua changes
            Hyprland.refreshToplevels();
            Hyprland.refreshWorkspaces();
            Hyprland.refreshMonitors();

            // Force JSON to fetch window positions as well
            root.scheduleClientsUpdate();

            // Stop after ~2.5 seconds (when Lua has certainly finished)
            if (bootRetryCount >= 6) {
                running = false;
            }
        }
    }

    // ── 4. EVENT PROCESSING (IPC EVENTS) ────────────────────────────────
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = `${event?.name ?? ""}`;
            if (n.endsWith("v2"))
                return;

            // Was calling scheduleClientsUpdate() only inside specific
            // matched branches below — required correctly guessing the
            // exact Hyprland event name for every action that should
            // trigger a refresh. Got this wrong repeatedly for special-
            // workspace actions specifically (move-to-special + toggle
            // visible didn't match any of the explicit names/patterns
            // below, so windowList silently went stale and never
            // picked up the special-workspace window at all — even
            // though `hyprctl clients -j` itself already reported it
            // correctly). Unconditional now: every single event
            // schedules a refresh, debounced to 60ms regardless, so
            // this can never again silently miss an event whose exact
            // name we didn't happen to anticipate.
            root.scheduleClientsUpdate();

            if (["workspace", "moveworkspace", "focusedmon", "activespecial"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n)) {
                Hyprland.refreshToplevels();
            }
        }
    }

    // ── 5. PROCESSES FOR JSON DATA ──────────────────────────────────────
    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windowList = JSON.parse(text);
                    const byAddr = {};
                    for (const w of root.windowList)
                        byAddr[w.address] = w;
                    root.windowByAddress = byAddr;
                    root.addresses = root.windowList.map(w => w.address);
                } catch (e) {
                    console.warn("HyprlandData: failed to parse clients:", e);
                }
            }
        }
    }

    // Per-client mapped/hidden/visible fields in `hyprctl clients -j`
    // do NOT reliably reflect whether a special workspace is actually
    // toggled visible right now — they stayed "mapped: true, hidden:
    // false" even while the special workspace containing that client
    // was hidden (same false-positive already hit with DropTermService
    // — see chat). `hyprctl monitors -j`'s specialWorkspace field per
    // monitor is the one place that's actually reliable for this,
    // confirmed working there already.
    property var monitorSpecialWorkspaceByName: ({}) // screenName -> "special:name" or "" if none shown

    Process {
        id: getMonitorsSpecial
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const mons = JSON.parse(text);
                    const map = {};
                    for (const m of mons)
                        map[m.name] = (m.specialWorkspace && m.specialWorkspace.name) ? m.specialWorkspace.name : "";
                    root.monitorSpecialWorkspaceByName = map;
                } catch (e) {
                    console.warn("HyprlandData: failed to parse monitors (special):", e);
                }
            }
        }
    }

    // ── 6. HELPER FUNCTIONS FOR WALLPAPER AND ACTIVE WINDOW ─────────────
    function activeWindowForScreen(screenName) {
        const monitor = root.monitors.values.find(m => m.name === screenName);
        if (!monitor || !monitor.activeWorkspace)
            return null;

        const tops = monitor.activeWorkspace.toplevels.values;
        if (tops.length === 0)
            return null;

        // .activated marks the single globally-focused toplevel in
        // Hyprland — find it among THIS workspace's windows first.
        // Falls back to tops[0] only if none of them are the globally
        // active one (e.g. focus is currently on a different
        // monitor's workspace entirely).
        const active = tops.find(t => t.activated);
        return active ?? tops[0];
    }

    function hasFullscreenOnScreen(screenName) {
        const monitor = root.monitors.values.find(m => m.name === screenName);
        return monitor && monitor.activeWorkspace ? monitor.activeWorkspace.hasFullscreen : false;
    }

    // A special workspace showing on top of the regular active
    // workspace never changes monitor.activeWorkspace at all — so
    // activeWindowForScreen (which only ever looks at activeWorkspace)
    // had no way to see it. Concretely: opening a special-workspace
    // window (e.g. a dropdown terminal) while the underlying regular
    // workspace was empty still reported "showing wallpaper", so
    // WallpaperOverlay rendered right on top of a window that was
    // actually covering the whole screen.
    //
    // Was checking windowList's per-client mapped/hidden fields —
    // confirmed unreliable (stayed "mapped: true, hidden: false" even
    // while the containing special workspace was actually hidden, so
    // this was permanently true the moment ANY window had ever been
    // moved to a special workspace, regardless of whether it was
    // currently shown — exactly the over-eager bug reported). monitors
    // .specialWorkspace (see getMonitorsSpecial above) is the
    // confirmed-reliable source for "is a special workspace actually
    // visible on this monitor right now" — same source already proven
    // correct for DropTermService's own state tracking.
    function _hasVisibleSpecialWorkspace(screenName) {
        return (root.monitorSpecialWorkspaceByName[screenName] ?? "") !== "";
    }

    function isShowingWallpaper(screenName) {
        if (root.activeWindowForScreen(screenName) !== null)
            return false;
        if (root._hasVisibleSpecialWorkspace(screenName))
            return false;
        return true;
    }

    readonly property bool anyScreenShowingWallpaper: {
        let showing = false;
        for (let i = 0; i < root.monitors.values.length; i++) {
            if (root.isShowingWallpaper(root.monitors.values[i].name)) {
                showing = true;
                break;
            }
        }
        return showing;
    }
}
