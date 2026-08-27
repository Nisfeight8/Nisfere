import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    property string label: ""
    property string value: ""
    property color valueColor: Theme.foreground
    property bool valueBold: true
    property real uiScale: 1.0

    Layout.fillWidth: true

    Text {
        Layout.fillWidth: true
        text: root.label
        color: Theme.foreground
        opacity: 0.7
        font.family: Theme.fontName
        font.pixelSize: 13 * root.uiScale
    }
    Text {
        text: root.value
        color: root.valueColor
        font.family: Theme.fontName
        font.pixelSize: 13 * root.uiScale
        font.bold: root.valueBold

        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }
}
