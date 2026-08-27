import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

BarWidget {
    id: clockWidget

    property bool opened: false

    bgColor: "transparent"
    spacing: 8

    // ── Main click zone: calendar + date/time → toggle Tabs ────────
    Item {
        id: mainArea
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: mainRow.implicitWidth
        implicitHeight: mainRow.implicitHeight

        RowLayout {
            id: mainRow
            anchors.fill: parent
            spacing: 8

            LucideIcon {
                Layout.alignment: Qt.AlignVCenter
                color: Theme.selected
                size: clockWidget.iconSize
                icon: "calendar"
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: clockWidget.fontSize
                text: Qt.formatDateTime(TimeService.date, "ddd dd MMM • HH:mm")
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: {
                const screenName = QsWindow.window?.screen?.name ?? "";
                ShellState.toggleDashboardTabs(screenName);
            }
        }
    }

    Item {
        height: 1
        width: 4
    }

    // ── Status icon cluster ─────────────────────────────────────────
    RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Media playing indicator
        Item {
            Layout.alignment: Qt.AlignVCenter
            visible: MediaService.isPlaying
            height: clockWidget.iconSize + 4
            width: clockWidget.iconSize + 4

            LucideIcon {
                anchors.centerIn: parent
                color: Theme.selected
                size: clockWidget.iconSize
                icon: "music"
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: {
                    const screenName = QsWindow.window?.screen?.name ?? "";
                    ShellState.toggleDashboardTab(screenName, 1); // Media tab
                }
            }
        }

        // "You left something open" indicator
        Item {
            id: resumableIndicator
            Layout.alignment: Qt.AlignVCenter
            visible: ShellState.dashboardHasResumableComponentActive
            height: clockWidget.iconSize + 4
            width: clockWidget.iconSize + 4

            readonly property var _icons: ({
                    "docker": "container",
                    "sysmon": "activity",
                    "settings": "settings",
                    "git": "git-branch"
                })

            LucideIcon {
                anchors.centerIn: parent
                color: Theme.selected
                size: clockWidget.iconSize
                icon: resumableIndicator._icons[ShellState.dashboardResumableComponent] ?? "circle"
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    const screenName = QsWindow.window?.screen?.name ?? "";
                    ShellState.toggleDashboardComponent(screenName, ShellState.dashboardResumableComponent);
                }
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: ShellState.forgetResumableComponent()
            }
        }

        // Notification bell
        Item {
            Layout.alignment: Qt.AlignVCenter
            visible: NotificationService.notifications.length > 0
            height: clockWidget.iconSize + 4
            width: clockWidget.iconSize + 4

            LucideIcon {
                anchors.centerIn: parent
                color: Theme.selected
                size: clockWidget.iconSize
                icon: "bell"
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: -6
                anchors.top: parent.top
                anchors.topMargin: -4
                color: Theme.color1
                height: clockWidget.smallFontSize + 5
                radius: height / 2
                width: height

                Text {
                    anchors.centerIn: parent
                    color: Theme.background
                    font.bold: true
                    font.pixelSize: clockWidget.smallFontSize
                    text: NotificationService.notifications.length
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: {
                    const screenName = QsWindow.window?.screen?.name ?? "";
                    ShellState.toggleDashboardTab(screenName, 3); // Notifications tab
                }
            }
        }
    }
}
