import QtQuick
import qs.core

Rectangle {
    id: root

    property bool checked: false
    property real uiScale: 1.0
    signal toggled

    readonly property bool isHovered: hover.hovered

    width: 44 * uiScale
    height: 24 * uiScale
    radius: height / 2
    color: checked ? Theme.selected : Theme.backgroundAlt
    border.width: checked ? 0 : 1
    border.color: isHovered ? Theme.selected : Theme.borderColor

    Behavior on color {
        AnimColor {
            type: Anim.FastEffects
        }
    }
    Behavior on border.color {
        AnimColor {
            type: Anim.FastEffects
        }
    }

    Rectangle {
        width: root.height * 0.75
        height: width
        radius: width / 2
        y: (parent.height - height) / 2
        x: root.checked ? parent.width - width - (3 * root.uiScale) : (3 * root.uiScale)
        color: root.checked ? Theme.background : Theme.foreground

        Behavior on x {
            Anim {
                type: Anim.FastToggle
            }
        }
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        onTapped: root.toggled()
    }
}
