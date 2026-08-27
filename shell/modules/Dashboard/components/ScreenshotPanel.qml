import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

FocusScope {
    id: root
    // Bottom-up from `row` (the button RowLayout) — the countdown
    // overlay below uses anchors.fill: parent, so it doesn't factor
    // into sizing, only `row`'s own content does. Deliberately no
    // anchors.fill on root itself — this is a small, compact popup-
    // style standalone Dashboard component (see
    // ShellState.dashboardActiveComponent), not a big persistent tool
    // like Settings/Docker, so it's meant to size itself to its own
    // small content rather than filling the whole panel.
    property real uiScale: 1.0

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Same keyboard navigation as RecordPanel.qml — Left/Right
    // move, Enter/Return/Space activates. FocusScope + forceActiveFocus
    // so Keys.onXxx here actually receives events once this page loads.
    // Now that this is a standalone top-level Dashboard component
    // (not nested inside a QuickActions container that used to handle
    // Escape itself), Escape is handled directly here too.
    property int currentIndex: 0
    property bool keyboardNavActive: false

    focus: true
    Component.onCompleted: {
        keyboardNavActive = true;
        currentIndex = 0
        forceActiveFocus();
    }

    Keys.onEscapePressed: ShellState.closeDashboard()
    Keys.onLeftPressed: {
        keyboardNavActive = true;
        currentIndex = (currentIndex - 1 + _options.length) % _options.length;
    }
    Keys.onRightPressed: {
        keyboardNavActive = true;
        currentIndex = (currentIndex + 1) % _options.length;
    }
    Keys.onUpPressed: {
        keyboardNavActive = true;
        currentIndex = (currentIndex - 1 + _options.length) % _options.length;
    }
    Keys.onDownPressed: {
        keyboardNavActive = true;
        currentIndex = (currentIndex + 1) % _options.length;
    }
    Keys.onReturnPressed: _triggerOption(currentIndex)
    Keys.onEnterPressed: _triggerOption(currentIndex)
    Keys.onSpacePressed: _triggerOption(currentIndex)

    readonly property var _options: [
        {
            icon: "monitor",
            label: "Full screen",
            mode: "full"
        },
        {
            icon: "app-window",
            label: "Window",
            mode: "window"
        },
        {
            icon: "crop",
            label: "Area",
            mode: "area"
        },
        {
            icon: "timer",
            label: "2 seconds",
            mode: "delay2"
        },
        {
            icon: "timer",
            label: "5 seconds",
            mode: "delay5"
        },
    ]

    // Shared by both mouse taps and keyboard activation. Was
    // ShellState.quickAction = ""; ShellState.quickActionsOpened =
    // false — both gone now, closeDashboard() is the one universal
    // way out of any Dashboard component.
    function _triggerOption(index) {
        const modelData = _options[index];
        ShellState.closeDashboard();
        ScreenshotService.capture(modelData.mode);
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 14

        Repeater {
            model: root._options

            CircularActionButton {
                icon: modelData.icon
                label: modelData.label
                uiScale: root.uiScale
                tooltipText: ""
                // Keyboard-selected option reuses the same hover
                // visuals — see CircularActionButton.forceHover.
                forceHover: root.keyboardNavActive && root.currentIndex === index

                onTapped: {
                    root.keyboardNavActive = false;
                    root._triggerOption(index);
                }
            }
        }
    }

    // ── Countdown overlay (delay2/delay5) ─────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.9)
        visible: ScreenshotService.isCapturing && ScreenshotService.countdown > 0

        Text {
            anchors.centerIn: parent
            text: ScreenshotService.countdown
            color: Theme.selected
            font.family: Theme.fontName
            font.pixelSize: 42
            font.bold: true
        }
    }
}
