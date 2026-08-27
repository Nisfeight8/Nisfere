import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    anchors.fill: parent
    implicitWidth: mainColumn.implicitWidth
    implicitHeight: mainColumn.implicitHeight

    ColumnLayout {
        id: mainColumn
        anchors.centerIn: parent
        spacing: 26 * root.uiScale

        // ── Mode toggle ───────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10 * root.uiScale

            Repeater {
                model: [
                    {
                        key: "focus",
                        label: "Focus",
                        icon: "brain"
                    },
                    {
                        key: "break",
                        label: "Break",
                        icon: "coffee"
                    },
                ]
                NavTile {
                    id: modeBtn
                    isActive: FocusService.mode === modelData.key
                    Layout.fillWidth: true
                    uiScale: root.uiScale
                    icon: modelData.icon
                    label: modelData.label
                    onTapped: FocusService.switchMode(modelData.key)
                }
            }
        }

        // ── Ring + duration adjust ────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20 * root.uiScale

            IconButton {
                icon: "minus"
                size: 46 * root.uiScale
                iconSize: 18 * root.uiScale
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                enabled: !FocusService.running
                tooltipText: "-" + (FocusService.stepSeconds / 60) + " min"
                onTapped: FocusService.decreaseDuration()
            }

            ColumnLayout {
                spacing: 6 * root.uiScale
                CircularGauge {
                    Layout.alignment: Qt.AlignHCenter
                    width: 220 * root.uiScale
                    height: 220 * root.uiScale
                    value: FocusService.progress
                    mainText: FocusService.formatTime()
                    subText: FocusService.mode === "focus" ? "Focus" : "Break"
                    progressColor: FocusService.mode === "focus" ? Theme.selected : Theme.color2
                    showSideText: false
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: FocusService.formatDuration() + " session"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12 * root.uiScale
                    opacity: 0.5
                }
            }

            IconButton {
                icon: "plus"
                size: 46 * root.uiScale
                iconSize: 18 * root.uiScale
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                enabled: !FocusService.running
                tooltipText: "+" + (FocusService.stepSeconds / 60) + " min"
                onTapped: FocusService.increaseDuration()
            }
        }

        // ── Controls ──────────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16 * root.uiScale

            IconButton {
                icon: "rotate-ccw"
                size: 44 * root.uiScale
                iconSize: 18 * root.uiScale
                activeSolid: true
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                tooltipText: "Reset"
                onTapped: FocusService.reset()
            }

            IconButton {
                icon: FocusService.running ? "pause" : "play"
                size: 60 * root.uiScale
                iconSize: 26 * root.uiScale
                activeSolid: true
                radius: Theme.radius
                normalColor: Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15)
                hoverColor: Theme.selected
                activeColor: Theme.selected
                isActive: FocusService.running
                tooltipText: FocusService.running ? "Pause" : "Start"
                onTapped: FocusService.toggle()
            }
        }
    }
}
