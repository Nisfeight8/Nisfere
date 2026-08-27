import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

BarWidget {
    id: root

    property bool statsOpen: false

    useGradient: true
    

    // ── CPU ──────────────────────────────────────────────────────
    Item {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: widgetHeight - 4
        implicitHeight: widgetHeight - 4

        MiniGauge {
            anchors.fill: parent
            value: SystemStatsService.cpuUsage
            progressColor: SystemStatsService.cpuUsage > 0.8 ? Theme.color1 : Theme.selected
        }
        LucideIcon {
            anchors.centerIn: parent
            icon: "cpu"
            size: widgetHeight / 2.2
            color: SystemStatsService.cpuUsage > 0.8 ? Theme.color1 : Theme.selected

            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }
        }
    }

    // ── RAM ──────────────────────────────────────────────────────
    Item {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: widgetHeight - 4
        implicitHeight: widgetHeight - 4

        MiniGauge {
            anchors.fill: parent
            value: SystemStatsService.ramUsage
            progressColor: Theme.color2
        }
        LucideIcon {
            anchors.centerIn: parent
            icon: "memory-stick"
            size: widgetHeight / 2.2
            color: Theme.color2
        }
    }

    // ── Disk ─────────────────────────────────────────────────────
    Item {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: widgetHeight - 4
        implicitHeight: widgetHeight - 4

        MiniGauge {
            anchors.fill: parent
            value: parseFloat(SystemStatsService.diskUsage) / 100
            progressColor: Theme.color3
        }
        LucideIcon {
            anchors.centerIn: parent
            icon: "hard-drive"
            size: widgetHeight / 2.2
            color: Theme.color3
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        onTapped: root.statsOpen = !root.statsOpen
    }

    BarPopup {
        showPopup: root.statsOpen
        targetItem: root

        contentComponent: Component {
            // ColumnLayout continuously recomputes its OWN
            // implicitWidth from its children/layout algorithm —
            // setting it directly (as we tried) gets silently
            // overwritten on the next relayout, which happens
            // constantly here since the stats update reactively. A
            // plain Item's implicitWidth is a normal, freely-assignable
            // property that nothing else recomputes, so we fix the
            // width there and let the ColumnLayout just fill it.
            Item {
                implicitWidth: 340
                implicitHeight: statsColumn.implicitHeight

                ColumnLayout {
                    id: statsColumn
                    anchors.fill: parent
                    spacing: 16

                    // ── CPU ───────────────────────────────────────────
                StatChartCard {
                    icon: "cpu"
                    title: "CPU"
                    accentColor: SystemStatsService.cpuUsage > 0.8 ? Theme.color1 : Theme.selected
                    chartValues: SystemStatsService.cpuHistory

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Usage"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            opacity: 0.75
                        }
                        Text {
                            text: Math.round(SystemStatsService.cpuUsage * 100) + "%"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Temperature"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            opacity: 0.75
                        }
                        Text {
                            text: SystemStatsService.cpuTempText
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                // ── RAM ───────────────────────────────────────────
                StatChartCard {
                    icon: "memory-stick"
                    title: "Memory"
                    accentColor: Theme.color2
                    chartValues: SystemStatsService.ramHistory

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Used"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            opacity: 0.75
                        }
                        Text {
                            text: SystemStatsService.ramUsedText + " / " + SystemStatsService.ramTotalText
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                // ── Disk — no chart, usage barely changes moment
                // to moment so a sparkline wouldn't show anything
                // meaningful. Same header style for consistency.
                StatChartCard {
                    icon: "hard-drive"
                    title: "Storage"
                    accentColor: Theme.color3
                    chartValues: null

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Used"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            opacity: 0.75
                        }
                        Text {
                            text: SystemStatsService.diskUsedText + " / " + SystemStatsService.diskTotalText + " (" + SystemStatsService.diskUsage + ")"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                // ── Network ───────────────────────────────────────
                StatChartCard {
                    icon: "arrow-up-down"
                    title: "Network"
                    accentColor: Theme.color5
                    chartValues: SystemStatsService.netHistory

                    RowLayout {
                        Layout.fillWidth: true
                        LucideIcon {
                            icon: "arrow-down"
                            size: 13
                            color: Theme.color2
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Download"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            opacity: 0.75
                        }
                        Text {
                            text: SystemStatsService.netDownText
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        LucideIcon {
                            icon: "arrow-up"
                            size: 13
                            color: Theme.color2
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Upload"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            opacity: 0.75
                        }
                        Text {
                            text: SystemStatsService.netUpText
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        LucideIcon {
                            icon: "history"
                            size: 13
                            color: Theme.foreground
                            opacity: 0.6
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Total (session)"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            opacity: 0.75
                        }
                        Text {
                            text: "↓" + SystemStatsService.formatBytes(SystemStatsService.totalDownBytes) + " ↑" + SystemStatsService.formatBytes(SystemStatsService.totalUpBytes)
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderColor
                    opacity: 0.4
                }

                NavTile {
                    Layout.fillWidth: true
                    icon: "layout-dashboard"
                    label: "Full System Monitor"
                    onTapped: {
                        ShellState.appLauncherOpened = true;
                        ShellState.launcherActiveTab = 1;
                        ShellState.launcherActiveTool = "sysmon";
                        root.statsOpen = false;
                    }
                }
                }
            }
        }
    }
}
