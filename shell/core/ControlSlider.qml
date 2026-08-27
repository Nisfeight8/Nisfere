import QtQuick
import QtQuick.Controls
import qs.core

Slider {
    id: control

    property bool isMuted: false
    property real uiScale: 1.0

    property color progressColor: Theme.selected
    property color trackColor: Theme.background

    from: 0
    hoverEnabled: true
    implicitHeight: 32 * uiScale
    implicitWidth: 150 * uiScale
    to: 1

    background: Rectangle {
        color: control.trackColor
        height: 24 * control.uiScale
        radius: height / 2
        width: control.availableWidth
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2

        Rectangle {
            color: control.isMuted ? Theme.borderColor : control.progressColor
            height: parent.height
            radius: parent.radius
            width: control.visualPosition * parent.width
        }
    }
    handle: Rectangle {
        border.color: Theme.background
        border.width: 2
        color: control.pressed ? Theme.foreground : Theme.selected
        implicitHeight: 36 * control.uiScale
        implicitWidth: 16 * control.uiScale
        opacity: (control.hovered || control.pressed) ? 1.0 : 0.0
        radius: width / 2
        scale: (control.hovered || control.pressed) ? 1.0 : 0.5
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
        Behavior on scale {
            Anim {
                type: Anim.FastEffects
            }
        }
    }
}
