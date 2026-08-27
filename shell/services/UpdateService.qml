pragma Singleton
import QtQuick
import Quickshell

import qs.services

Singleton {
    id: root

    property var updates: []
    property int count: 0
    property bool loading: false
    property bool updateRunning: false
    property var updateLog: []
    property string lastCheck: ""

    signal updatesLoaded(int count)
    signal updateLogLine(string line, string status)

    property Connections _conn: Connections {
        target: SocketService

        function onMessageReceived(type, payload) {
            switch (type) {
            case "arch_updates":
                root.updates = payload.updates ?? [];
                root.count = payload.count ?? 0;
                root.loading = false;
                root.lastCheck = Qt.formatTime(new Date(), "HH:mm");
                root.updatesLoaded(root.count);
                break;
            case "update_stream":
                let line = payload.line ?? "";
                let status = payload.status ?? "running";

                if (status === "start") {
                    root.updateLog = [line];
                    root.updateRunning = true;
                } else if (status === "done" || status === "error") {
                    root.updateLog = [...root.updateLog, line];
                    root.updateRunning = false;
                } else {
                    root.updateLog = [...root.updateLog, line];
                }
                root.updateLogLine(line, status);
                break;
            }
        }
    }

    function loadCached() {
        SocketService.sendCommand("updates", "get_cached_updates", {});
    }

    function refresh() {
        root.loading = true;
        SocketService.sendCommand("updates", "check_updates", {});
    }

    function runUpdates() {
        root.updateLog = [];
        root.updateRunning = true;
        SocketService.sendCommand("updates", "run_updates", {});
    }

    function clearLog() {
        root.updateLog = [];
    }
}
