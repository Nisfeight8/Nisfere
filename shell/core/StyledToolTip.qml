import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

// Themed tooltip — positioned centered below its parent by default.
// NOTE: only works reliably in drawers/panels — do NOT use inside the
// Bar (its Popup/Overlay machinery doesn't play nicely with the Bar's
// own hosting window; see BarTooltip.qml, which exists specifically
// as a PopupWindow-based workaround for that case).
// Usage: StyledToolTip { visible: hover.hovered; text: "..." }
ToolTip {
    id: root

    // Computed locally rather than accepting a uiScale prop — this
    // component is instantiated from dozens of unrelated callsites
    // throughout the shell, so requiring every one of them to
    // remember to pass uiScale would just recreate the same class of
    // "forgot to wire it" bug we already hit multiple times on the
    // Dashboard. Same self-sufficient pattern as BarWidget/BarPopup.
    readonly property real uiScale: Theme.scaleFor(QsWindow.window?.screen)

    delay: 200
    y: parent.height + (15 * uiScale)
    x: (parent.width - width) / 2

    padding: 6 * uiScale
    leftPadding: 12 * uiScale
    rightPadding: 12 * uiScale

    contentItem: Text {
        text: root.text
        color: Theme.selected
        font.family: Theme.fontName
        font.pixelSize: 14 * root.uiScale
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }

    background: Rectangle {
        color: Theme.backgroundAlt
        border.color: Theme.borderColor
        border.width: 1
        radius: 8 * root.uiScale

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
    }
}
