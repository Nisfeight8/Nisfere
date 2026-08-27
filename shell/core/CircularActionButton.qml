import QtQuick
import QtQuick.Layouts
import qs.core

ColumnLayout {
    id: root

    property string icon: ""
    property string label: ""
    property bool showLabel: true
    property bool isActive: false
    property bool showPulse: false
    property color pulseColor: Theme.color1
    property color activeColor: Theme.color1
    property color hoverColor: Theme.selected
    property string tooltipText: label
    property int diameter: 52
    property int iconSize: 20
    property real uiScale: 1.0

    readonly property bool isHovered: hover.hovered || forceHover
    property bool forceHover: false
    readonly property color _stateColor: root.isActive ? Theme.backgroundAlt : root.isHovered ? root.hoverColor : Theme.foreground

    signal tapped

    spacing: 6 * root.uiScale

    Rectangle {
        id: circle
        Layout.alignment: Qt.AlignHCenter
        width: root.diameter * root.uiScale
        height: root.diameter * root.uiScale
        radius: width / 2

        color: root.isActive ? root.activeColor : root.isHovered ? Qt.rgba(root.hoverColor.r, root.hoverColor.g, root.hoverColor.b, 0.40) : Theme.background
        border.width: Theme.widgetBorderWidth
        border.color: root.isActive ? root.activeColor : root.isHovered ? root.hoverColor : Theme.borderColor

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

        LucideIcon {
            anchors.centerIn: parent
            icon: root.icon
            size: root.iconSize * root.uiScale
            color: root._stateColor
            opacity: root.isActive ? 1.0 : root.isHovered ? 0.95 : 0.65
            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }
            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 2
            border.color: root.pulseColor
            visible: root.showPulse
            opacity: 0.7

            SequentialAnimation on opacity {
                running: root.showPulse
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.15
                    duration: 700
                }
                NumberAnimation {
                    to: 0.7
                    duration: 700
                }
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: root.showLabel
        text: root.label
        color: root.isActive ? root.activeColor : root.isHovered ? root.hoverColor : Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 10 * root.uiScale
        opacity: root.isActive ? 1.0 : root.isHovered ? 0.9 : 0.6
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
        Behavior on opacity {
            Anim {
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
    StyledToolTip {
        visible: root.isHovered && root.tooltipText !== ""
        text: root.tooltipText
    }
}
