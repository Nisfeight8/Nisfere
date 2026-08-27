pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string backlightPath: ""
    property real currentBrightness: 0
    property real maxBrightness: 100
    property bool isAvailable: backlightPath !== ""
    property real percentage: maxBrightness > 0 ? (currentBrightness / maxBrightness) : 0

    property Process _detect_device: Process {
        id: backlightProcess

        stdout: StdioCollector {
            onStreamFinished: {
                let devices = text.trim().split('\n');
                let devName = devices[0];

                if (devName !== "") {
                    root.backlightPath = "/sys/class/backlight/" + devName;
                    console.log("Found Backlight:", root.backlightPath);
                } else {
                    console.warn("No display brightness control found.");
                }
            }
        }

        Component.onCompleted: {
            exec(["ls", "/sys/class/backlight"]);
        }
    }

    property FileView _maxFile: FileView {
        path: root.backlightPath !== "" ? root.backlightPath + "/max_brightness" : ""

        onTextChanged: {
            let val = parseInt(text().trim());
            if (!isNaN(val))
                root.maxBrightness = val;
        }
    }

    property FileView _currentFile: FileView {
        path: root.backlightPath !== "" ? root.backlightPath + "/brightness" : ""
        watchChanges: true

        onFileChanged: reload()

        onTextChanged: {
            let val = parseInt(text().trim());
            if (!isNaN(val)) {
                root.currentBrightness = val;
            }
        }
    }

    function setPercentage(val) {
        if (!isAvailable)
            return;

        val = Math.max(0.0, Math.min(1.0, val));

        let absTarget = Math.round(root.maxBrightness * val);

        let minBrightness = Math.round(root.maxBrightness * 0.05);
        if (absTarget < minBrightness) {
            absTarget = minBrightness;
        }

        Quickshell.execDetached(["brightnessctl", "s", absTarget.toString()]);
    }
}
