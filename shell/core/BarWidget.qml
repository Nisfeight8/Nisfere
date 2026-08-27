import QtQuick
import Quickshell
import qs.core

Item {
    id: root

    readonly property real _uiScale: Theme.scaleFor(QsWindow.window?.screen)
    property color bgColor: Theme.backgroundAlt
    default property alias content: contentRow.data
    property int paddingX: 12
    property alias spacing: contentRow.spacing
    property bool useGradient: false

    property int widgetHeight: Theme.scaledBarHeight(QsWindow.window?.screen) - (15 * _uiScale)

    readonly property real iconSize: Math.max(13, widgetHeight * 0.55)
    readonly property real fontSize: Math.max(11, widgetHeight * 0.37)
    readonly property real smallFontSize: Math.max(9, widgetHeight * 0.31)

    readonly property alias contentRow: contentRow

    // The widget's STABLE preferred content width — defaults to
    // contentRow.implicitWidth (fine for ordinary widgets whose
    // children never shrink, e.g. BatteryWidget/AudioWidget/etc, since
    // there's nothing there that varies live). Widgets that CAN shrink
    // (like ActiveWindow's title) must override this with a formula
    // based only on stable/natural sizes (Text.implicitWidth, which is
    // always the FULL unelided metric regardless of the text's actual
    // current `width` or `elide` state) — never based on
    // contentRow.width or any child's live/current width. Using a live
    // width here is what caused the flicker: it made root's own
    // "preferred size" depend on the very shrink decision that's
    // itself based on comparing against root's preferred size — a
    // genuine binding loop, not just a visual bug.
    property real naturalContentWidth: contentRow.implicitWidth

    // Computed from naturalContentWidth (stable) vs root.width
    // (assigned externally, top-down, by the outer RowLayout) — since
    // naturalContentWidth can no longer be affected by the outcome of
    // this comparison, this can't oscillate.
    readonly property bool _isConstrained: root.width > 0 && root.width < implicitWidth

    implicitHeight: bgRect.implicitHeight
    implicitWidth: bgRect.implicitWidth

    Rectangle {
        id: bgRect

        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: root.useGradient ? "transparent" : root.bgColor
        implicitHeight: root.widgetHeight
        implicitWidth: root.naturalContentWidth + (root.paddingX * 2)
        width: root._isConstrained ? root.width : implicitWidth
        radius: Theme.radius

        Behavior on implicitWidth {
            Anim {
                type: Anim.FastSpatial
            }
        }

        GlassBackground {
            visible: root.useGradient
        }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8
            width: bgRect.width - (root.paddingX * 2)
        }
    }
}
