import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    property string activeIcon: "volume-2"
    property string mutedIcon: "volume-x"
    property bool isMuteable: false
    property bool isMuted: false
    property real uiScale: 1.0

    property real value: 0.0
    property string valueText: (root.isMuteable && root.isMuted) ? "Mute" : Math.round(internalSlider.value * 100) + "%"

    signal toggleMuteClicked
    signal liveValueMoved(real newValue)
    signal finalValueChanged(real newValue)

    Layout.fillWidth: true
    spacing: 12 * root.uiScale

    Rectangle {
        border.color: (root.isMuteable && root.isMuted) ? Theme.borderColor : "transparent"
        color: (root.isMuteable && root.isMuted) ? Theme.backgroundAlt : "transparent"
        height: 36 * root.uiScale
        radius: width / 2
        width: 36 * root.uiScale

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
            size: 18 * root.uiScale
            color: (root.isMuteable && root.isMuted) ? Theme.foreground : Theme.selected
            opacity: (root.isMuteable && root.isMuted) ? 0.5 : 1.0
            icon: root.isMuted ? root.mutedIcon : root.activeIcon

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
            enabled: root.isMuteable
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            enabled: root.isMuteable
            onTapped: root.toggleMuteClicked()
        }
    }

    ControlSlider {
        id: internalSlider
        Layout.fillWidth: true
        isMuted: root.isMuteable && root.isMuted
        uiScale: root.uiScale

        Binding {
            target: internalSlider
            property: "value"
            value: root.value
            when: !internalSlider.pressed
            restoreMode: Binding.RestoreNone
        }

        onMoved: root.liveValueMoved(internalSlider.value)
        onPressedChanged: if (!pressed)
            root.finalValueChanged(internalSlider.value)
    }

    Text {
        Layout.preferredWidth: 35 * root.uiScale
        color: Theme.foreground
        font.pixelSize: 12 * root.uiScale
        horizontalAlignment: Text.AlignRight
        opacity: 0.7
        text: root.valueText
    }
}
