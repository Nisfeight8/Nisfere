import QtQuick
import QtQuick.Layouts
import qs.core

GlassCard {
    id: root

    property string icon: ""
    property string title: ""
    property color accentColor: Theme.selected
    property var chartValues: null   // null = no chart
    property real chartHeight: 40

    // Detail rows declared inside StatChartCard{} land here
    default property alias rows: rowsColumn.data

    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight + 24
    
    // color: Theme.backgroundAlt
    // radius: Theme.radius
    // border.color: Theme.borderColor
    // border.width: Theme.widgetBorderWidth

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ── Header ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            LucideIcon {
                icon: root.icon
                size: 16
                color: root.accentColor
            }
            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 14
                font.bold: true
            }
        }

        // ── Chart ────────────────────────────────────────
        Sparkline {
            Layout.fillWidth: true
            Layout.preferredHeight: root.chartHeight
            visible: root.chartValues !== null
            values: root.chartValues ?? []
            lineColor: root.accentColor
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.3
            visible: root.chartValues !== null
        }

        // ── Details ──────────────────────────────────────
        ColumnLayout {
            id: rowsColumn
            Layout.fillWidth: true
            spacing: 6
        }
    }
}