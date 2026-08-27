import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

PanelWindow {
    id: powerMenu

    visible: ShellState.powerMenuOpened
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    readonly property real uiScale: Theme.scaleFor(screen)

    // Which action is currently highlighted for keyboard navigation —
    // reset to 0 every time the menu opens, so it never remembers an
    // odd position from a previous session.
    property int currentIndex: 0
    onVisibleChanged: {
        if (visible)
            currentIndex = 0;
    }

    // Named here (not inline in the Repeater below) so the Shortcut
    // handlers can reference its length/entries without duplicating
    // the model.
    readonly property var actionsModel: [
        {
            icon: "power",
            label: "Shutdown",
            action: () => PowerService.poweroff(),
            color: Theme.color1
        },
        {
            icon: "refresh-cw",
            label: "Reboot",
            action: () => PowerService.reboot(),
            color: Theme.color2
        },
        {
            icon: "moon",
            label: "Suspend",
            action: () => PowerService.suspend(),
            color: Theme.color3
        },
        {
            icon: "lock",
            label: "Lock",
            action: () => PowerService.lock(),
            color: Theme.color4
        },
        {
            icon: "log-out",
            label: "Logout",
            action: () => PowerService.logout(),
            color: Theme.color5
        },
    ]

    function _activateCurrent() {
        const item = powerMenu.actionsModel[powerMenu.currentIndex];
        if (!item)
            return;
        ShellState.powerMenuOpened = false;
        item.action();
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Shortcut {
        sequence: "Escape"
        onActivated: ShellState.powerMenuOpened = false
    }
    Shortcut {
        sequence: "Left"
        onActivated: powerMenu.currentIndex = (powerMenu.currentIndex - 1 + powerMenu.actionsModel.length) % powerMenu.actionsModel.length
    }
    Shortcut {
        sequence: "Right"
        onActivated: powerMenu.currentIndex = (powerMenu.currentIndex + 1) % powerMenu.actionsModel.length
    }
    Shortcut {
        sequence: "Return"
        onActivated: powerMenu._activateCurrent()
    }
    Shortcut {
        // Separate key sequence from "Return" (main Enter key) — this
        // is the numpad Enter, distinct binding in Qt's key sequence
        // grammar even though both keys conventionally "confirm".
        sequence: "Enter"
        onActivated: powerMenu._activateCurrent()
    }

    GlassBackground {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.4
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.powerMenuOpened = false
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 60 * powerMenu.uiScale

        // ── Header ────────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10 * powerMenu.uiScale

            Text {
                text: "Goodbye, " + SystemInfo.username
                font.family: Theme.fontName
                font.pixelSize: 32 * powerMenu.uiScale
                font.bold: true
                color: Theme.selected
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: SystemInfo.osName + " • " + SystemInfo.uptime
                font.family: Theme.fontName
                font.pixelSize: 16 * powerMenu.uiScale
                color: Theme.selected
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // ── Action buttons ────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 40 * powerMenu.uiScale

            Repeater {
                model: powerMenu.actionsModel

                CircularActionButton {
                    icon: modelData.icon
                    showLabel: false
                    diameter: 140
                    iconSize: 48
                    uiScale: powerMenu.uiScale

                    hoverColor: modelData.color
                    activeColor: modelData.color
                    tooltipText: modelData.label

                    // NOT VERIFIED: assumes CircularActionButton has
                    // an `isActive`-style property (matching
                    // IconButton's own isActive/activeColor
                    // convention elsewhere in this shell) that
                    // visually highlights it — if the real component
                    // uses a different property name for this, swap
                    // it in here.
                    isActive: index === powerMenu.currentIndex

                    onTapped: {
                        powerMenu.currentIndex = index;
                        powerMenu._activateCurrent();
                    }
                }
            }
        }
    }
}
