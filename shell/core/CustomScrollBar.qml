// core/CustomScrollBar.qml
import QtQuick
import QtQuick.Controls
import qs.core

ScrollBar {
    id: control

    property color handleColor: Theme.foreground
    property color handleHoverColor: Theme.selected
    property real handleOpacity: 0.3
    property real handleHoverOpacity: 0.6
    property real uiScale: 1.0
    property real barThickness: 6 * uiScale

    policy: ScrollBar.AsNeeded
    interactive: true
    minimumSize: 0.08

    // Only ever visible when content genuinely overflows the
    // viewport (size < 1.0 means "the handle covers less than the
    // full track", i.e. there's more content than fits). This single
    // condition now governs BOTH the handle (contentItem) and the
    // track (background) together, instead of policy/size doing it
    // implicitly and inconsistently between the two.
    readonly property bool _overflowing: size < 1.0
    visible: _overflowing

    // Matches the pointing-hand cursor convention already used on
    // every other interactive control in this shell (IconButton,
    // NavTile, ...). Only ever active while the ScrollBar itself is
    // visible (i.e. genuinely overflowing) — nothing extra to guard
    // here, an invisible control doesn't receive hover input anyway.
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    contentItem: Rectangle {
        implicitWidth: control.barThickness
        implicitHeight: control.barThickness
        radius: width / 2
        color: control.pressed || control.hovered ? control.handleHoverColor : control.handleColor
        opacity: control.pressed || control.hovered ? control.handleHoverOpacity : control.handleOpacity

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }

    background: Rectangle {
        implicitWidth: control.barThickness
        implicitHeight: control.barThickness
        radius: width / 2
        color: Theme.backgroundAlt
        opacity: 0.2
    }
}
