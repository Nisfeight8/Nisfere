pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"

GlassCard {
    id: root
    property real uiScale: 1.0
    Layout.fillWidth: true

    implicitHeight: slidersColumn.implicitHeight + (30 * root.uiScale)

    Component {
        id: brightnessComp
        Brightness {
            uiScale: root.uiScale
        }
    }

    ColumnLayout {
        id: slidersColumn
        anchors.fill: parent
        anchors.margins: 15 * root.uiScale
        spacing: 15 * root.uiScale

        Volume {
            Layout.fillWidth: true
            uiScale: root.uiScale
        }

        Mic {
            id: mic
            Layout.fillWidth: true
            uiScale: root.uiScale
        }

        Loader {
            id: brightnessLoader
            active: BrightnessService.isAvailable
            visible: BrightnessService.isAvailable
            asynchronous: true
            sourceComponent: brightnessComp
            Layout.fillWidth: true
            Layout.preferredHeight: BrightnessService.isAvailable ? brightnessLoader.implicitHeight : 0
        }
    }
}
