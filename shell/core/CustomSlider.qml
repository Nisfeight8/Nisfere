import QtQuick
import QtQuick.Controls
import qs.core

Slider {
    id: control

    property color progressColor: Theme.selected
    property color trackColor: Theme.backgroundAlt
    property real uiScale: 1.0

    from: 0
    hoverEnabled: true
    to: 1

    background: Rectangle {
        color: control.trackColor
        height: implicitHeight
        implicitHeight: 8 * control.uiScale
        implicitWidth: 150 * control.uiScale
        radius: height / 2
        width: control.availableWidth
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2

        Rectangle {
            color: control.progressColor
            height: parent.height
            radius: parent.radius
            width: control.visualPosition * parent.width
        }
    }
    handle: Rectangle {
        border.color: Theme.background
        border.width: 2
        color: control.pressed || control.hovered ? Theme.foreground : Theme.selected
        implicitHeight: 16 * control.uiScale
        implicitWidth: 16 * control.uiScale
        radius: width / 2
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2

        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }
}
