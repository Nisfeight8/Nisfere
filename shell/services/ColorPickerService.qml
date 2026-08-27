pragma Singleton
import Quickshell
import Quickshell.Io

// Runs hyprpicker and copies the result — extracted out of
// QuickActions.qml into its own singleton (same reasoning as
// TimeService/CalendarService) specifically because the ORIGINAL
// wiring was broken: QuickActionsContent.qml (a separate file) tried
// to call `root._runColorPicker()` — `root` is QuickActions.qml's own
// BaseDrawer id, not visible across a file boundary no matter how
// deeply nested inside a Component block. A plain "QuickActions.
// _runColorPicker()" call elsewhere in the same file assumed
// QuickActions was a singleton, which it isn't either. Making this a
// real singleton means ANY file can just call
// ColorPickerService.run() directly, no cross-file scope issues.
//
// We capture hyprpicker's stdout ourselves and copy it via wl-copy,
// rather than relying on hyprpicker's built-in -a/--autocopy flag —
// that depends on wl-clipboard being present and has been flaky on
// some versions. Doing it explicitly guarantees the copy happens,
// and lets us show a notification with the picked color.
Singleton {
    id: root

    property Process _pickerProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let hex = text.trim();
                if (hex) {
                    root._copyProc.command = ["wl-copy", hex];
                    root._copyProc.running = true;
                    InternalNotificationService.send("Color picked", hex, "color-picker");
                } else {
                    InternalNotificationService.send("Color picker cancelled", "", "color-picker", "low");
                }
            }
        }
    }
    property Process _copyProc: Process {
        running: false
    }

    function run() {
        _pickerProc.command = ["hyprpicker", "-f", "hex"];
        _pickerProc.running = true;
    }
}
