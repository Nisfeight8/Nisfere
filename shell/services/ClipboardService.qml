pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Clipboard history via cliphist (pacman: cliphist).
// Requires the cliphist store daemon running in hyprland.conf:
//   exec-once = wl-paste --watch cliphist store
Singleton {
    id: root

    property var  entries: []   // [{id, preview, raw}]
    property bool loading: false

    // ── List ─────────────────────────────────────────────────────
    property Process _listProc: Process {
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "");
                root.entries = lines.map(line => {
                    const tabIdx = line.indexOf("\t");
                    return {
                        id:      tabIdx >= 0 ? line.slice(0, tabIdx)   : line,
                        preview: tabIdx >= 0 ? line.slice(tabIdx + 1)  : line,
                        raw:     line   // full line — required by cliphist decode/delete
                    };
                });
                root.loading = false;
            }
        }
    }

    function refresh() {
        root.loading = true;
        _listProc.running = true;
    }

    // ── Copy ─────────────────────────────────────────────────────
    // Pass the raw line as an argv element (not shell-interpolated) —
    // avoids any quoting issues with special characters in clipboard
    // content. "$1" inside the script refers to it safely regardless
    // of quotes/tabs/newlines it might contain.
    property Process _copyProc: Process { running: false }

    function copyEntry(raw) {
        _copyProc.command = [
            "bash", "-c",
            "printf '%s' \"$1\" | cliphist decode | wl-copy",
            "_", raw
        ];
        _copyProc.running = true;
        InternalNotificationService.send("Copied to clipboard", "", "edit-copy");
    }

    // ── Delete single entry ──────────────────────────────────────
    property Process _deleteProc: Process {
        running: false
        onExited: root.refresh()
    }

    function deleteEntry(raw) {
        _deleteProc.command = [
            "bash", "-c",
            "printf '%s' \"$1\" | cliphist delete",
            "_", raw
        ];
        _deleteProc.running = true;
    }

    // ── Wipe all ─────────────────────────────────────────────────
    property Process _wipeProc: Process {
        running: false
        onExited: root.refresh()
    }

    function wipeAll() {
        _wipeProc.command = ["cliphist", "wipe"];
        _wipeProc.running = true;
    }
}
