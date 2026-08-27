import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services
import "widgets"

Item {
    id: root
    readonly property real uiScale: Theme.scaleFor(QsWindow.window?.screen)

    anchors.fill: parent

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 12

        SystemDrawerHeader {
            Layout.fillWidth: true
            // fillHeight removed — this widget's implicitHeight already
            // reflects its real content size; it doesn't need to grow.
            uiScale: root.uiScale
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.35
        }

        SystemDrawerUpdates {
            Layout.fillWidth: true
            uiScale: root.uiScale
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.35
            visible: BatteryService.hasBattery
        }

        BatteryCard {
            Layout.fillWidth: true
            uiScale: root.uiScale
            visible: BatteryService.hasBattery
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.35
        }

        // The ONLY fillHeight child now — absorbs all remaining
        // vertical space after the compact-content siblings above take
        // exactly what they need.
        SystemDrawerStats {
            Layout.fillWidth: true
            Layout.fillHeight: true
            uiScale: root.uiScale
        }
    }
}