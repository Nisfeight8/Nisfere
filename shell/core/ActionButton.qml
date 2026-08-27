import QtQuick
import qs.core

Rectangle {
    id: root

    property string label: ""
    property color baseColor: Theme.selected
    property real uiScale: 1.0

    readonly property bool isHovered: hover.hovered
    readonly property int _horizontalPadding: 16 * uiScale
    implicitWidth: labelText.implicitWidth + _horizontalPadding * 2
    height: 40 * uiScale
    radius: Theme.radius
    color: isHovered ? baseColor : "transparent"
    border.width: 1
    border.color: baseColor

    signal tapped

    Behavior on color {
        AnimColor {
            type: Anim.FastEffects
        }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.isHovered ? Theme.background : root.baseColor
        font.family: Theme.fontName
        font.pixelSize: 14 * root.uiScale
        font.bold: true
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
        onTapped: root.tapped()
    }
}
