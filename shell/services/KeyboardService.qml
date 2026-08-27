pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: keyboardService

    property Process _initProc: Process {
        command: ["hyprctl", "devices", "-j"]
        environment: ({
                "HYPRLAND_INSTANCE_SIGNATURE": Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
            })

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text;

                if (!txt || txt.length === 0) {
                    console.error("Hyprctl returned nothing. Check your environment variables.");
                    return;
                }

                try {
                    const data = JSON.parse(txt);
                    const kb = data.keyboards?.find(k => k.main);
                    if (kb) {
                        currentLayout = kb.active_keymap.substring(0, 2).toLowerCase();
                        availableLayouts = kb.layout ? kb.layout.split(",") : [];
                    }
                } catch (e) {
                    console.error("JSON Parse Error:", e);
                }
            }
        }
    }
    property Process _switcherProc: Process {}
    property var availableLayouts: []
    property string currentLayout: ""
    readonly property var layoutMap: {
        "us": {
            "short": "US",
            "full": "English (US)"
        },
        "en": {
            "short": "US",
            "full": "English (US)"
        },
        "gr": {
            "short": "GR",
            "full": "Ελληνικά (GR)"
        },
        "fr": {
            "short": "FR",
            "full": "Français (FR)"
        },
        "de": {
            "short": "DE",
            "full": "Deutsch (DE)"
        }
    }

    function changeLayout(index) {
        _switcherProc.exec(["hyprctl", "switchxkblayout", "current", index.toString()]);
    }
    function toggleLayout() {
        _switcherProc.exec(["hyprctl", "switchxkblayout", "current", "next"]);
    }
    function getFull(code) {
        return layoutMap[code]?.full || code.toUpperCase();
    }
    function getShort(code) {
        return layoutMap[code]?.short || code.toUpperCase();
    }
    function handleRawEvent(event) {
        if (event.name === "activelayout") {
            const parts = event.data.split(",");
            if (parts.length > 1) {
                currentLayout = parts[1].trim().substring(0, 2).toLowerCase();
            }
        }
    }

    Component.onCompleted: {
        Hyprland.rawEvent.connect(handleRawEvent);
        _initProc.running = true;
    }
}
