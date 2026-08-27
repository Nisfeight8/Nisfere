import QtQuick
import Quickshell.Widgets
import qs.core

// Was manually reimplementing margin + size-hugging via childrenRect —
// the exact pattern flagged in Quickshell's sizing docs as a latent
// binding-loop risk (implicit size derived from the child's ACTUAL
// geometry instead of its implicit size). Swapped for WrapperItem,
// the built-in component for exactly this job (single child, margin,
// size-hugging), which correctly flows implicit size UP instead.
Item {
    id: container
    property real uiScale: 1.0
    default property alias content: contentWrapper.child
    property int padding: 30 * uiScale
    property int minWidth: 150 * uiScale
    property int minHeight: 80 * uiScale

    // Off for consumers (BarPopup) that already drive opacity/y from
    // their own pre-animated offset — leaving this on for those would
    // double-animate (a Behavior smoothing values that are already
    // smooth just adds extra lag). BarTooltip leaves this at the
    // default (true) and keeps animating via these Behaviors as before.
    property bool selfAnimated: true

    implicitWidth: Math.max(minWidth, contentWrapper.implicitWidth)
    implicitHeight: Math.max(minHeight, contentWrapper.implicitHeight)

    // Same motion split used by BaseDrawer/AnimLoader across the shell:
    // position (y) is a spatial move, opacity is a pure fade/effect —
    // each gets the matching Material-3-derived curve from our Anim system.
    Behavior on opacity {
        enabled: container.selfAnimated
        Anim {
            type: Anim.FastEffects
        }
    }
    Behavior on y {
        enabled: container.selfAnimated
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    PanelShape {
        anchors.fill: parent
        edge: Qt.TopEdge
    }

    WrapperItem {
        id: contentWrapper
        anchors.fill: parent
        margin: container.padding
    }
}
