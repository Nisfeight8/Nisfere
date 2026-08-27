import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

FocusScope {
    id: root
    // Deliberately no anchors.fill on root — same reasoning as
    // ScreenshotPanel.qml: small, compact popup-style standalone
    // Dashboard component, sized to its own content, not stretched to
    // fill the whole panel.
    property real uiScale: 1.0
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

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
    ]

    // Same keyboard navigation as ScreenshotPanel.qml — Left/Right
    // cycle the mode options (only meaningful while not recording —
    // while recording there's just the one Stop action), Enter/
    // Return/Space activates. Escape now handled directly here too
    property int currentIndex: 0
    property bool keyboardNavActive: false

    focus: true
    Component.onCompleted: {
        keyboardNavActive = true;
        currentIndex = 0;
        forceActiveFocus();
    }

    Keys.onEscapePressed: ShellState.closeDashboard()
    Keys.onLeftPressed: {
        keyboardNavActive = true;
        if (!ScreenRecordService.isRecording)
            currentIndex = (currentIndex - 1 + _options.length) % _options.length;
    }
    Keys.onRightPressed: {
        keyboardNavActive = true;
        if (!ScreenRecordService.isRecording)
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
    Keys.onReturnPressed: _triggerCurrent()
    Keys.onEnterPressed: _triggerCurrent()
    Keys.onSpacePressed: _triggerCurrent()

    function _triggerCurrent() {
        if (ScreenRecordService.isRecording) {
            // Previously stopped WITHOUT closing the dashboard, to
            // navigate back to QuickActionsBar (the row of 6 icons)
            // within the same still-open drawer — that "bar" no
            // longer exists (this panel is a standalone top-level
            // component now, no nested pages to return to), so
            // stopping now just closes the dashboard like every other
            // action here.
            ScreenRecordService.stop();
            ShellState.closeDashboard();
            return;
        }
        const modelData = _options[currentIndex];
        ShellState.closeDashboard();
        ScreenRecordService.start(modelData.mode);
    }

    Item {
        id: content
        anchors.fill: parent
        implicitWidth: ScreenRecordService.isRecording ? recordingRow.implicitWidth : optionsRow.implicitWidth
        implicitHeight: ScreenRecordService.isRecording ? recordingRow.implicitHeight : optionsRow.implicitHeight

        // ── Options (shown when not recording) ────────────────────
        RowLayout {
            id: optionsRow
            anchors.centerIn: parent
            spacing: 14
            visible: !ScreenRecordService.isRecording

            Repeater {
                model: root._options

                CircularActionButton {
                    icon: modelData.icon
                    label: modelData.label
                    uiScale: root.uiScale
                    hoverColor: Theme.selected
                    activeColor: Theme.color1
                    tooltipText: ""
                    // Keyboard-selected option reuses the same hover
                    // visuals — see CircularActionButton.forceHover.
                    forceHover: root.keyboardNavActive && root.currentIndex === index

                    onTapped: {
                        root.keyboardNavActive = false;
                        root.currentIndex = index;
                        root._triggerCurrent();
                    }
                }
            }
        }

        // ── Recording indicator (shown while recording) ───────────
        RowLayout {
            id: recordingRow
            anchors.centerIn: parent
            spacing: 18
            visible: ScreenRecordService.isRecording

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: Theme.color1
                SequentialAnimation on opacity {
                    running: ScreenRecordService.isRecording
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.25
                        duration: 650
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: 650
                    }
                }
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Recording..."
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    text: ScreenRecordService.formatDuration()
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    opacity: 0.6
                }
            }

            CircularActionButton {
                uiScale: root.uiScale
                icon: "square"
                label: "Stop"
                diameter: 52
                iconSize: 18
                tooltipText: ""
                isActive: true
                activeColor: Theme.color1
                hoverColor: Theme.selected
                showPulse: true
                pulseColor: Theme.selected
                // Only one action while recording — no left/right
                // needed, just highlight it once the user starts
                // navigating by keyboard at all.
                forceHover: root.keyboardNavActive

                onTapped: {
                    root.keyboardNavActive = false;
                    root._triggerCurrent();
                }
            }
        }
    }
}
