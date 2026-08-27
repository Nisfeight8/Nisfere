pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property Process _cavaProc: Process {
        id: cava

        command: ["cava", "-p", Quickshell.shellPath("assets/cava.conf")]
        running: root.isActive

        stdout: SplitParser {
            onRead: data => {
                // Single-pass parse — the old version did
                // split → filter → map (3 separate array traversals,
                // 2 throwaway intermediate arrays) on EVERY cava output
                // line. At cava's frame rate (dozens of times/sec while
                // music plays), that adds up to a huge number of small
                // JS array allocations — confirmed via QML Profiler as
                // the single biggest "LargeItem" memory churn source in
                // the whole shell. One pass avoids the intermediate
                // arrays entirely.
                const parts = data.trim().split(";");
                const currentBars = [];
                const maxBassBars = 3;
                let bassSum = 0;
                let bassCount = 0;
                let totalSum = 0;

                for (let i = 0; i < parts.length; i++) {
                    const s = parts[i];
                    if (s === "")
                        continue;
                    const val = Number(s);
                    currentBars.push(val);
                    totalSum += val;
                    if (currentBars.length <= maxBassBars) {
                        bassSum += val;
                        bassCount++;
                    }
                }

                if (currentBars.length === 0)
                    return;

                root.bars = currentBars;
                root.bass = bassCount > 0 ? bassSum / bassCount : 0;
                root.level = totalSum / currentBars.length;
            }
        }
    }
    property var bars: []
    property real bass: 0

    // ── Wallpaper-visualizer gating ─────────────────────────────────
    // "Is there at least one screen right now showing wallpaper (no
    // activated window on it) with nothing else open" — the actual
    // per-screen active-window check now lives in one place,
    // ActiveWindow bar widget instead of being copy-pasted here too.

    readonly property bool anyScreenShowingWallpaper: HyprlandData.anyScreenShowingWallpaper

    // Only run cava (and all the per-frame parsing above) while
    // something is actually going to consume `bars`/`bass`/`level` —
    // either the Dashboard's Media tab (glow effect) or the wallpaper
    // visualizer overlay when the desktop is showing. Previously this
    // ran the ENTIRE time music was playing, even with nothing open to
    // see it — by far the largest single contributor to background
    // CPU/memory churn found via profiling. The compact bar indicators
    // (Clock's disc icon, NowPlaying) don't use this data, so gating
    // it here costs nothing visually.
    property bool isActive: MediaService.isPlaying && ((ShellState.dashboardOpened && ShellState.dashboardTabsCurrentTab === 1) || root.anyScreenShowingWallpaper)
    property real level: 0

    onIsActiveChanged: {
        if (!isActive) {
            root.bars = [];
            root.bass = 0;
            root.level = 0;
        }
    }
}
