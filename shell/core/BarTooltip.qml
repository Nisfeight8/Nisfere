import QtQuick
import Quickshell
import qs.core

// Tooltip for items INSIDE the bar. Unlike StyledToolTip (which works
// fine in Drawers), the bar's own hosting window (now ScreenBorder,
// previously its own small PanelWindow) needs a genuinely separate
// PopupWindow surface to paint "below the bar" outside its own bounds.
//
// anchor.window uses targetItem's QsWindow.window — Quickshell's OWN
// attached property (not standard Qt's `Window.window`, which returns
// a generic Qt window proxy that Quickshell's anchor system doesn't
// accept — that was the "ProxiedWindow... which is not a quickshell
// window" warning from the first attempted fix). QsWindow.window gives
// the actual Quickshell window instance ultimately hosting this Item,
// rather than a hardcoded id reference like the old `myBar` (which
// broke once Bar.qml became a plain Item, no longer its own window,
// hosted inside ScreenBorder instead).
PopupWindow {
    id: root

    property string text: ""
    property real uiScale: Theme.scaleFor(QsWindow.window?.screen)
    required property bool showPopup
    required property Item targetItem

    property real targetX: targetItem.mapToItem(null, 0, 0).x + (targetItem.width / 2) - (root.width / 2)
    anchor.rect.x: Math.max(8, targetX)
    anchor.rect.y: Theme.scaledBarHeight(QsWindow.window?.screen)
    anchor.window: targetItem.QsWindow.window

    color: "transparent"
    implicitWidth: container.implicitWidth
    implicitHeight: container.implicitHeight
    visible: showPopup || container.opacity > 0

    PopupContainer {
        id: container
        uiScale: root.uiScale
        opacity: root.showPopup ? 1 : 0
        y: root.showPopup ? 0 : -10

        Text {
            text: root.text
            color: Theme.selected
            font.family: Theme.fontName
            font.pixelSize: 14 * root.uiScale
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
        }
    }
}
