pragma Singleton
import QtQuick
import Quickshell

import qs.services

Singleton {
    id: root

    // ── CPU ───────────────────────────────────────────────────────
    property real cpuUsage: 0.0
    property string cpuTempText: "0°C"

    // ── RAM ───────────────────────────────────────────────────────
    property real ramUsage: 0.0
    property string ramUsedText: "0GiB"
    property string ramTotalText: "0GiB"

    // ── Disk ──────────────────────────────────────────────────────
    property string diskUsage: "0%"
    property string diskUsedText: "0G"
    property string diskTotalText: "0G"

    // ── Network ───────────────────────────────────────────────────
    property string netDownText: "0 B/s"
    property string netUpText: "0 B/s"
    property real netDownMbps: 0.0
    property real netUpMbps: 0.0

    // Session-accumulated totals — the daemon only reports instantaneous
    // rates (netDownMbps/netUpMbps), not cumulative bytes transferred.
    // We approximate a running total client-side by integrating the
    // rate over elapsed time between updates. This is an estimate (not
    // exact metering — depends on update cadence catching bursts), but
    // good enough for an at-a-glance "how much have I used this
    // session" figure.
    property real totalDownBytes: 0
    property real totalUpBytes: 0
    property real _lastUpdateMs: 0

    function formatBytes(bytes) {
        if (bytes < 1024)
            return Math.round(bytes) + " B";
        if (bytes < 1024 * 1024)
            return (bytes / 1024).toFixed(1) + " KB";
        if (bytes < 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(1) + " MB";
        return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GB";
    }

    // ── Rolling history for sparkline charts ────────────────────────
    readonly property int historyLength: 40
    property var cpuHistory: []
    property var ramHistory: []
    property var netHistory: []   // combined down+up activity, normalized 0..1

    readonly property real _netHistoryScaleMbps: 50   // adjust to taste — controls sparkline sensitivity

    function _pushHistory(arr, value) {
        let updated = arr.concat([value]);
        if (updated.length > historyLength)
            updated = updated.slice(updated.length - historyLength);
        return updated;
    }

    // ── Daemon message handler ────────────────────────────────────
    property Connections _conn: Connections {
        target: SocketService

        function onMessageReceived(type, payload) {
            if (type !== "sys_stats")
                return;
            root.cpuUsage = payload.cpuUsage ?? 0;
            root.cpuTempText = payload.cpuTempText ?? "N/A";
            root.ramUsage = payload.ramUsage ?? 0;
            root.ramUsedText = payload.ramUsedText ?? "0GiB";
            root.ramTotalText = payload.ramTotalText ?? "0GiB";
            root.diskUsage = payload.diskUsage ?? "0%";
            root.diskUsedText = payload.diskUsedText ?? "0G";
            root.diskTotalText = payload.diskTotalText ?? "0G";
            root.netDownText = payload.netDownText ?? "0 B/s";
            root.netUpText = payload.netUpText ?? "0 B/s";
            root.netDownMbps = payload.netDownMbps ?? 0;
            root.netUpMbps = payload.netUpMbps ?? 0;

            // Accumulate session totals — integrate rate × elapsed time
            const now = Date.now();
            if (root._lastUpdateMs > 0) {
                const deltaSeconds = (now - root._lastUpdateMs) / 1000;
                // Mbps = megabits/sec → ÷8 for megabytes, ×1e6 for bytes
                root.totalDownBytes += (root.netDownMbps * 1e6 / 8) * deltaSeconds;
                root.totalUpBytes += (root.netUpMbps * 1e6 / 8) * deltaSeconds;
            }
            root._lastUpdateMs = now;

            root.cpuHistory = root._pushHistory(root.cpuHistory, root.cpuUsage);
            root.ramHistory = root._pushHistory(root.ramHistory, root.ramUsage);
            root.netHistory = root._pushHistory(root.netHistory, Math.min(1.0, (root.netDownMbps + root.netUpMbps) / root._netHistoryScaleMbps));
        }
    }
}
