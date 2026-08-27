import QtQuick
import qs.core

// Pure geometry math for BaseDrawer.
//
// IMPORTANT: this is the Item-era version — windowWidth/windowHeight
// are GONE (the window itself no longer resizes; see BaseDrawer.qml).
// panelWidth/panelHeight (content-driven) now ONLY affect panelItem's
// own size/position inside its host, never any window's geometry.
//
// slideDistanceH/slideDistanceV are what panelItem's x/y calculations
// in BaseDrawer.qml actually reference — this file you had was
// missing these entirely (an older, pre-refactor version), which is
// what caused NaN positions/broken masking.
QtObject {
    id: root

    // ── Inputs ───────────────────────────────────────────────────
    property int edge: Qt.LeftEdge
    property bool cornerMode: false
    property bool sidePanelMode: false
    property int cornerSecondaryEdge: Qt.TopEdge
    property real edgeMargin: Theme.screenBorderSize

    property real minPanelWidth: 0
    property real minPanelHeight: 0
    property real maxPanelWidth: -1   // -1 = no limit
    property real maxPanelHeight: -1

    property real contentWidth: 0
    property real contentHeight: 0

    property real offset: 1.0  // 0 = fully open, 1 = fully closed (off-screen)
    property real screenOffset: 0

    // ── Derived: which edge(s) this drawer sits against ───────────
    readonly property bool isHorizontal: edge === Qt.LeftEdge || edge === Qt.RightEdge

    readonly property bool anchorTop: edge === Qt.TopEdge || (cornerMode && cornerSecondaryEdge === Qt.TopEdge) || sidePanelMode
    readonly property bool anchorBottom: edge === Qt.BottomEdge || (cornerMode && cornerSecondaryEdge === Qt.BottomEdge) || sidePanelMode
    readonly property bool anchorLeft: edge === Qt.LeftEdge || (cornerMode && cornerSecondaryEdge === Qt.LeftEdge)
    readonly property bool anchorRight: edge === Qt.RightEdge || (cornerMode && cornerSecondaryEdge === Qt.RightEdge)

    readonly property real _mTop: anchorTop ? 0 : 30
    readonly property real _mBottom: anchorBottom ? 0 : 30
    readonly property real _mLeft: anchorLeft ? 0 : 30
    readonly property real _mRight: anchorRight ? 0 : 30

    // ── Panel's own (content-driven) size — used ONLY for panelItem,
    // never for any window ────────────────────────────────────────
    // Raw computed target, kept private+readonly (pure math, nothing
    // ever writes to it). Behavior CANNOT attach to a readonly
    // property at all — QML rejects it outright, since Behavior works
    // by intercepting writes, which a readonly property never permits,
    // even for its own internal binding re-evaluation. So the public,
    // externally-referenced panelWidth/panelHeight below are instead
    // plain writable properties bound to these targets, WITH a
    // Behavior attached — same computed value, just animatable.
    readonly property real _targetPanelWidth: {
        const w = Math.max(minPanelWidth, contentWidth + _mLeft + _mRight);
        return maxPanelWidth > 0 ? Math.min(w, maxPanelWidth) : w;
    }
    readonly property real _targetPanelHeight: {
        const h = Math.max(minPanelHeight, contentHeight + _mTop + _mBottom);
        return maxPanelHeight > 0 ? Math.min(h, maxPanelHeight) : h;
    }

    // Was an instant snap. The AnimLoader's own fade only hides the
    // CONTENT jumping; the panel's own background/shape
    // (DrawerBackground/PanelShape) is bound to these two properties
    // and is ALWAYS visible (never faded), so its edges were still
    // hard-snapping to the new size on every tab switch, just without
    // visibly reshuffled content inside it. This Behavior makes that
    // resize smooth, independent of the content fade timing — both
    // look good whether or not they finish at the same moment.
    property real panelWidth: _targetPanelWidth
    property real panelHeight: _targetPanelHeight

    Behavior on panelWidth {
        Anim {
            type: Anim.DefaultSpatial
        }
    }
    Behavior on panelHeight {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    // ── Slide distance — always non-negative, scales 0 (open) to
    // full panel extent (closed). THIS is what BaseDrawer.qml's
    // panelItem x/y actually reference — was missing entirely before.
    readonly property real slideDistanceH: (panelWidth + screenOffset) * offset
    readonly property real slideDistanceV: (panelHeight + screenOffset) * offset
}
