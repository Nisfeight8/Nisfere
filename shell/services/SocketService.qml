pragma Singleton
import QtQuick
import Quickshell

import Quickshell.Io

Singleton {
    id: root

    // ── Socket ───────────────────────────────────────────────────
    property Socket clientSocket: Socket {
        id: clientSocketId
        connected: true
        path: "/tmp/nisfere-shell.sock"

        parser: SplitParser {
            onRead: message => {
                try {
                    let data = JSON.parse(message);
                    root.messageReceived(data.type, data.payload);
                } catch (e) {
                    console.warn("SocketService: JSON parse error:", e);
                }
            }
        }

        onConnectedChanged: {
            if (!connected) {
                console.log("SocketService: Lost connection to daemon, retrying...");
                reconnectTimer.start();
            } else {
                console.log("SocketService: Connected to Nisfere Daemon");
                reconnectTimer.stop();
                root.connected();
            }
        }
    }

    // ── Auto-reconnect ───────────────────────────────────────────
    property Timer reconnectTimer: Timer {
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (!clientSocketId.connected)
                clientSocketId.connected = true;
        }
    }

    // ── Signals ──────────────────────────────────────────────────
    signal messageReceived(string type, var payload)
    signal connected

    // ── API ──────────────────────────────────────────────────────
    function sendCommand(module, action, payload) {
        if (!clientSocketId.connected) {
            console.warn("SocketService: Cannot send — not connected");
            return;
        }
        let msg = JSON.stringify({
            module: module,
            action: action,
            payload: payload ?? {}
        }) + "\n";
        clientSocketId.write(msg);
        clientSocketId.flush();
    }
}
