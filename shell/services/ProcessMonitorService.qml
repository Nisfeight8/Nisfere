pragma Singleton
import QtQuick
import Quickshell

import qs.services

// Polls the daemon for the process list — but ONLY while `polling` is
// true (the System Monitor tool sets this on open/close). Same lesson
// learned from AudioVisualizer: don't do expensive periodic work when
// nobody's looking at the result.
Singleton {
    id: root

    property var processes: []
    property bool polling: false

    property Timer _pollTimer: Timer {
        interval: 3000
        repeat: true
        running: root.polling
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function refresh() {
        SocketService.sendCommand("processes", "get_processes", {});
    }

    property Connections _conn: Connections {
        target: SocketService
        function onMessageReceived(type, payload) {
            if (type !== "process_list")
                return;
            root.processes = payload.processes ?? [];
        }
    }
}
