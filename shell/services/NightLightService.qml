pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property Process _hyprctlProc: Process {}
    property FileView _stateFile: FileView {
        blockLoading: true
        path: Quickshell.env("HOME") + "/.cache/nisfere/nightlight_state"
        watchChanges: true

        onLoaded: {
            root.isActive = (text().trim() === "1");
        }
        onTextChanged: {
            root.isActive = (text().trim() === "1");
        }
    }
    property bool isActive: false

    function toggle() {
        const newState = !root.isActive;

        if (newState) {
            _stateFile.setText("1");
            Quickshell.execDetached(["wlsunset", "-T", "10000", "-t", "4000"]);
        } else {
            _stateFile.setText("0");
            Quickshell.execDetached(["pkill", "wlsunset"]);
        }
    }
}
