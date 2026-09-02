pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    // ── State ─────────────────────────────────────────────────────
    property bool isRecording: false
    property string outputPath: ""
    property int duration: 0

    // ── Signals ───────────────────────────────────────────────────
    signal started(string path)
    signal stopped(string path)
    signal failed(string error)

    onFailed: error => InternalNotificationService.send("Recording failed", error, "dialog-error", "critical")

    function _outputPath() {
        let dir = Quickshell.env("HOME") + "/Videos/Recordings";
        return dir + "/" + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss") + ".mp4";
    }

    // ── Single shell command per mode ───────────────────────────────
    // Per Quickshell docs: Process.command does NOT run in a shell.
    // Must wrap with ["bash", "-c", "<cmd>"] for $() substitution to work.
    property Process _recorderProc: Process {
        running: false
        onExited: code => {
            console.log("ScreenRecordService: exit code", code, "duration:", root.duration);
            root.isRecording = false;
            _durationTimer.stop();
            if ((code === 0 || code === 130) && root.duration > 0) {
                InternalNotificationService.sendWithActions("Recording saved", root.outputPath.split("/").pop() + " · " + root.formatDuration(), "video", "normal", [
                    {
                        id: "open",
                        label: "Open Video",
                        command: ["xdg-open", root.outputPath]
                    },
                    {
                        id: "show",
                        label: "Show in Files",
                        command: ["dbus-send", "--session", "--dest=org.freedesktop.FileManager1", "--type=method_call", "/org/freedesktop/FileManager1", "org.freedesktop.FileManager1.ShowItems", `array:string:file://${root.outputPath}`, "string:"]
                    }
                ]);
                root.stopped(root.outputPath);
            } else {
                root.failed("wf-recorder exited immediately (exit " + code + ")");
            }
        }
    }

    property Process _stopProc: Process {
        running: false
    }

    property Timer _durationTimer: Timer {
        interval: 1000
        repeat: true
        onTriggered: root.duration++
    }

    property Timer _areaRecordTimer: Timer {
        interval: 100
        property string geom
        onTriggered: root._run(`wf-recorder -a -g "${geom}" --file='${root.outputPath}'`)
    }

    // ── Pending-start delay (full/window only) ──────────────────────
    // Same reasoning as ScreenshotService's _pendingCaptureTimer/
    // _scheduleCapture: closeDashboard() only STARTS the drawer's
    // close animation, it doesn't finish instantly, so starting
    // wf-recorder right away risked the first moment(s) of the
    // recording showing the drawer itself still visibly closing. Lives
    // here (not in RecordPanel.qml) so any future entry point into
    // recording gets this correctly for free, instead of every caller
    // needing to remember to wait itself. "area" doesn't need this —
    // it already waits on you to interact with the area picker, which
    // only makes sense once the drawer is out of the way regardless.
    property Timer _pendingStartTimer: Timer {
        interval: ShellState.drawerDelayInterval
        property string pendingCmd: ""
        onTriggered: root._run(pendingCmd)
    }

    function _scheduleStart(bashCmd) {
        _pendingStartTimer.pendingCmd = bashCmd;
        _pendingStartTimer.restart();
    }

    function _run(bashCmd) {
        console.log("ScreenRecordService: running:", bashCmd);
        root.duration = 0;
        root.isRecording = true;
        _recorderProc.command = ["bash", "-c", bashCmd];
        _recorderProc.running = true;
        _durationTimer.start();
        root.started(root.outputPath);
    }

    // ── Public API ────────────────────────────────────────────────
    function start(mode) {
        if (root.isRecording)
            return;
        root.outputPath = root._outputPath();

        switch (mode) {
        case "full":
            root._scheduleStart(`wf-recorder -a --file='${root.outputPath}'`);
            break;
        case "area":
            AreaPickerService.request((x, y, w, h) => {
                const geom = `${Math.round(x)},${Math.round(y)} ${Math.round(w)}x${Math.round(h)}`;
                _areaRecordTimer.geom = geom;
                _areaRecordTimer.start();
            }, () => { /* nothing to unwind — isRecording was never set */ });
            break;
        case "window":
            root._scheduleStart(`wf-recorder -a -o "$(hyprctl activeworkspace -j | jq -r '.monitor')" --file='${root.outputPath}'`);
            break;
        }
    }

    function stop() {
        if (!root.isRecording)
            return;
        // SIGINT lets wf-recorder finalize the file cleanly
        _stopProc.command = ["pkill", "-INT", "wf-recorder"];
        _stopProc.running = true;
    }

    function formatDuration() {
        let h = Math.floor(root.duration / 3600);
        let m = Math.floor((root.duration % 3600) / 60);
        let s = root.duration % 60;
        let pad = n => n.toString().padStart(2, "0");
        return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`;
    }
}
