pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    // ── State ─────────────────────────────────────────────────────
    property bool isCapturing: false
    property int countdown: 0
    property string lastCapture: ""

    // ── Signals ───────────────────────────────────────────────────
    signal captured(string path)
    signal failed(string error)
    signal countdownTick(int remaining)

    onFailed: error => InternalNotificationService.send("Screenshot failed", error, "dialog-error", "critical")

    // Ensure output directory exists
    property Process _mkdirProc: Process {
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/Pictures/Screenshots"]
        running: true
    }

    function _outputPath() {
        let dir = Quickshell.env("HOME") + "/Pictures/Screenshots";
        return dir + "/" + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss") + ".png";
    }

    // ── Single shell command per mode ───────────────────────────────
    property Process _captureProc: Process {
        running: false
        onExited: code => {
            root.isCapturing = false;
            if (code === 0) {
                root.captured(root.lastCapture);
                InternalNotificationService.sendWithActions("Screenshot saved", root.lastCapture.split("/").pop(), root.lastCapture, "normal", [
                    {
                        id: "open",
                        label: "Open Image",
                        command: ["xdg-open", root.lastCapture]
                    },
                    {
                        id: "show",
                        label: "Show in Files",
                        command: ["dbus-send", "--session", "--dest=org.freedesktop.FileManager1", "--type=method_call", "/org/freedesktop/FileManager1", "org.freedesktop.FileManager1.ShowItems", `array:string:file://${root.lastCapture}`, "string:"]
                    }
                ]);
            } else {
                root.failed("grim/slurp failed (exit " + code + ")");
            }
        }
    }

    function _run(bashCmd) {
        _captureProc.command = ["bash", "-c", bashCmd];
        _captureProc.running = true;
    }

    // ── Pending-capture delay ────────────────────────────────────────
    // Gives the Dashboard drawer time to finish its close-slide
    // animation before grim actually fires — otherwise "Full screen" and
    // "Window" modes catch the drawer itself mid-close in the screenshot.
    property Timer _pendingCaptureTimer: Timer {
        interval: ShellState.drawerDelayInterval
        property string pendingCmd: ""
        onTriggered: root._run(pendingCmd)
    }

    function _scheduleCapture(bashCmd) {
        root.isCapturing = true;
        _pendingCaptureTimer.pendingCmd = bashCmd;
        _pendingCaptureTimer.restart();
    }

    // ── Countdown timer (delay2 / delay5) ──────────────────────────
    property Timer _delayTimer: Timer {
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--;
            root.countdownTick(root.countdown);
            if (root.countdown <= 0) {
                stop();
                root._doFull();
            }
        }
    }

    property bool areaPickerActive: false

    property Timer _areaCaptureTimer: Timer {
        interval: 60
        property string geom
        onTriggered: {
            root.lastCapture = root._outputPath();
            root._run(`grim -g "${geom}" '${root.lastCapture}'`);
        }
    }

    function _runAreaCapture(x, y, w, h) {
        _areaCaptureTimer.geom = `${Math.round(x)},${Math.round(y)} ${Math.round(w)}x${Math.round(h)}`;
        _areaCaptureTimer.start();
    }

    function _doFull() {
        root.lastCapture = root._outputPath();
        root._scheduleCapture(`grim '${root.lastCapture}'`);
    }

    // ── Public API ────────────────────────────────────────────────
    function capture(mode) {
        switch (mode) {
        case "full":
            _doFull();
            break;
        case "area":
            root.isCapturing = true;
            AreaPickerService.request((x, y, w, h) => root._runAreaCapture(x, y, w, h), () => {
                root.isCapturing = false;
            });
            break;
        case "window":
            root.lastCapture = root._outputPath();
            root._scheduleCapture(`grim -o "$(hyprctl activeworkspace -j | jq -r '.monitor')" '${root.lastCapture}'`);
            break;
        case "delay2":
            root.isCapturing = true;
            root.countdown = 2;
            root.countdownTick(2);
            _delayTimer.start();
            break;
        case "delay5":
            root.isCapturing = true;
            root.countdown = 5;
            root.countdownTick(5);
            _delayTimer.start();
            break;
        }
    }

    function cancel() {
        _delayTimer.stop();
        _pendingCaptureTimer.stop();
        if (_captureProc.running)
            _captureProc.running = false;
        root.isCapturing = false;
        root.countdown = 0;
    }
}
