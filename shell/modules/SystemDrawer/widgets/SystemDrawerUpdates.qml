import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8 * root.uiScale

        // ── Header row ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6 * root.uiScale

            LucideIcon {
                icon: "package-open"
                size: 14 * root.uiScale
                color: Theme.selected
            }

            Text {
                text: UpdateService.loading ? "Checking..." : UpdateService.updateRunning ? "Updating..." : UpdateService.count > 0 ? UpdateService.count + " update" + (UpdateService.count !== 1 ? "s" : "") + " available" : "System up to date"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13 * root.uiScale
                font.bold: true
                Layout.fillWidth: true
                leftPadding: 4 * root.uiScale
            }

            Text {
                text: UpdateService.lastCheck ? "· " + UpdateService.lastCheck : ""
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11 * root.uiScale
                opacity: 0.4
            }

            // ── Refresh button ─────────────────────────────────────
            IconButton {
                icon: "refresh-cw"
                size: 30 * root.uiScale
                iconSize: 14 * root.uiScale
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                tooltipText: "Check for updates"
                enabled: !UpdateService.loading && !UpdateService.updateRunning
                spinning: UpdateService.loading
                onTapped: UpdateService.refresh()
            }

            // ── Update All button ──────────────────────────────────
            IconButton {
                icon: "circle-fading-arrow-up"
                size: 30 * root.uiScale
                iconSize: 14 * root.uiScale
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                visible: UpdateService.count > 0 && !UpdateService.updateRunning
                hoverColor: Theme.color2
                activeColor: Theme.color2
                tooltipText: "Update all packages\nopens polkit dialog"
                onTapped: UpdateService.runUpdates()
            }

            // ── Close log button ───────────────────────────────────
            IconButton {
                icon: "x"
                size: 30 * root.uiScale
                iconSize: 13 * root.uiScale
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                visible: UpdateService.updateLog.length > 0 && !UpdateService.updateRunning
                hoverColor: Theme.color1
                activeColor: Theme.color1
                tooltipText: "Clear log"
                onTapped: UpdateService.clearLog()
            }
        }

        // ── Live update log ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120 * root.uiScale
            radius: Theme.radius
            color: Theme.backgroundAlt
            visible: UpdateService.updateLog.length > 0
            clip: true

            ListView {
                id: logView
                anchors {
                    fill: parent
                    margins: 8 * root.uiScale
                }
                model: UpdateService.updateLog
                spacing: 2 * root.uiScale
                clip: true

                onCountChanged: Qt.callLater(() => positionViewAtEnd())

                ScrollBar.vertical: CustomScrollBar {
                    uiScale: root.uiScale
                }
                delegate: Text {
                    width: logView.width
                    text: modelData
                    color: modelData.startsWith("Error") || modelData.includes("failed") ? Theme.color1 : modelData.includes("✓") || modelData.includes("up to date") ? Theme.color2 : Theme.foreground
                    font.family: "monospace"
                    font.pixelSize: 10 * root.uiScale
                    wrapMode: Text.WordWrap
                    opacity: 0.9
                }
            }
        }

        // ── Update package list ───────────────────────────────────
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(UpdateService.count * 26 * root.uiScale, 130 * root.uiScale)
            visible: UpdateService.count > 0 && UpdateService.updateLog.length === 0
            model: UpdateService.updates
            clip: true
            ScrollBar.vertical: CustomScrollBar {
                uiScale: root.uiScale
            }
            delegate: RowLayout {
                width: ListView.view.width
                height: 26 * root.uiScale
                spacing: 8 * root.uiScale

                Rectangle {
                    width: 3 * root.uiScale
                    height: 3 * root.uiScale
                    radius: Theme.radius
                    color: Theme.selected
                    opacity: 0.6
                }
                Text {
                    text: modelData.name
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: modelData.current
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 10 * root.uiScale
                    opacity: 0.4
                }
                LucideIcon {
                    icon: "arrow-right"
                    size: 10 * root.uiScale
                    color: Theme.selected
                    opacity: 0.6
                }
                Text {
                    text: modelData.new
                    color: Theme.color2
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                }
            }
        }
    }
}
