import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import "widgets"
import "widgets/Workspaces"
import "widgets/InternalTrayWidget"

Item {
    id: myBar

    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
    }
    height: Theme.scaledBarHeight(QsWindow.window?.screen)

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Item {
        id: contentArea
        anchors.fill: parent

        // Gap kept clear between each cluster and the clock — clusters
        // are never allowed to render closer to the clock than this.
        readonly property real clusterClockGap: 10

        // True visual center, always — independent of either cluster's
        // width, so this can never drift off-center the way two
        // unequal fillWidth spacers would (their split only balances
        // LEFTOVER space, not the clock's actual screen position).
        Clock {
            id: clockWidget
            anchors.centerIn: parent
        }

        // ── Left cluster ──────────────────────────────────────────
        RowLayout {
            id: leftCluster
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }
            spacing: 15
            clip: true

            // Capped so it can never render past the clock's left
            // edge. RowLayout, even with an explicit width smaller
            // than its children's summed preferred width, will shrink
            // any Layout.fillWidth child down toward its
            // Layout.minimumWidth to fit — that's what lets
            // ActiveWindow (below) absorb the squeeze via elide instead
            // of this cluster just overflowing past the clock.
            readonly property real availableWidth: Math.max(0, clockWidget.x - contentArea.clusterClockGap - x)
            width: Math.min(implicitWidth, availableWidth)

            LauncherButton {
                id: launcherButton
            }
            Workspaces {
                id: workspacesWidget
            }
            ActiveWindow {
                id: activeWindowWidget
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
        }

        // ── Right cluster ─────────────────────────────────────────
        RowLayout {
            id: rightCluster
            anchors {
                right: parent.right
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }
            spacing: 15
            clip: true

            // Mirror of leftCluster's cap — never renders past the
            // clock's right edge.
            readonly property real availableWidth: Math.max(0, contentArea.width - (clockWidget.x + clockWidget.width) - contentArea.clusterClockGap - (contentArea.width - x - width))
            width: Math.min(implicitWidth, availableWidth)

            RecordingIndicator {
                id: recordingIndicator
            }
            TrayWidget {
                id: sysTrayWidget
            }
            BatteryWidget {
                id: batteryWidget
            }
            AudioWidget {
                id: audioWidget
            }
            KeyboardWidget {
                id: keyboardWidget
            }
            InternalTrayWidget {
                id: internalSystemTrayWidget
            }
            PowerButton {
                id: powerButton
            }
        }
    }
}
