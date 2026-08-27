import QtQuick
import Quickshell
import qs.core
import qs.services

// Was a PopupWindow — its own separate Wayland surface, created/
// mapped fresh on first open. Rewritten as a plain Item, reparented
// into the SAME already-live window that hosts the bar/drawers
// (visualWindow in ScreenBorder.qml) — the same window already proven
// smooth for Dashboard/ControlCenter/SystemDrawer. No new surface ever
// gets created just to show a popup anymore.
//
// Two consequences of no longer being its own window:
//   1. Positioning is relative coordinates (x/y) within the shared
//      window instead of anchor.rect — targetItem.mapToItem(parent, ...)
//      does the same job anchor.rect's screen-relative math did.
//   2. Hit-testing needs an explicit mask carve-out (a plain Item has
//      none of its own) — see ShellState.registerPopup/unregisterPopup
//      and ScreenBorder's mask Region slots over activePopupItems.
Item {
    id: root

    default property Component contentComponent
    required property bool showPopup
    required property Item targetItem

    // Resolved once here, at the one place in this file that already
    // needs QsWindow.window?.screen (for scaledBarHeight) — passed
    // down to PopupContainer, which exposes it further to whatever
    // contentComponent is loaded inside, so popup content doesn't
    // need to re-derive this independently.
    readonly property real uiScale: Theme.scaleFor(QsWindow.window?.screen)

    // Reparent into the hosting window's root content item —
    // targetItem.QsWindow.window resolves to whichever actual window
    // (screen) hosts targetItem, same per-screen correctness the old
    // anchor.window: targetItem.QsWindow.window gave for free, just
    // expressed as a runtime reparent instead of a window anchor.
    parent: targetItem.QsWindow.window ? targetItem.QsWindow.window.contentItem : null
    // Above Dashboard/ControlCenter/SystemDrawer/Overview — the
    // highest z already in use in ScreenBorder is overviewLoader's 50.
    z: 200

    readonly property real targetX: targetItem.mapToItem(root.parent, 0, 0).x + (targetItem.width / 2) - (implicitWidth / 2)
    // Anchored to the bar's own height, not targetItem's position —
    // every bar popup now opens from directly under the bar itself,
    // regardless of which widget triggered it.
    readonly property real targetY: Theme.scaledBarHeight(QsWindow.window?.screen)

    x: Math.max(10, targetX)
    y: targetY
    implicitWidth: container.implicitWidth
    implicitHeight: container.implicitHeight
    width: implicitWidth
    // Was a fixed height (implicitHeight) with content sliding WITHIN
    // it via y — that revealed content bottom-to-top (the overlap
    // between the fixed clip window and the moving content started at
    // the content's BOTTOM edge), which read as "growing upward
    // inside a box", not "sliding down from the bar". Animating
    // root's OWN height instead — content stays fixed at its natural
    // size (see container below), the clip window itself grows from 0
    // to full — reveals top-to-bottom, the correct direction for
    // something unfurling out from under the bar.
    height: implicitHeight * (1.0 - motion.offset)
    clip: true
    // No window to make invisible anymore — same offset-driven
    // visibility the old `visible: motion.offset < 1` gave, just on a
    // plain Item now. Kept for the same reason: fully hides (and, via
    // the mask registry below, un-hit-tests) once the close animation
    // has actually finished, not the instant showPopup flips.
    visible: motion.offset < 1

    // Doesn't start the open animation until the content has actually
    // finished loading — avoids both earlier problems (mid-animation
    // pop-in with plain async loading, or a synchronous GUI-thread
    // freeze with sync loading) without needing to keep content
    // permanently loaded in memory.
    // Was `opened: root.showPopup && contentLoader.item !== null` —
    // referencing contentLoader (nested inside PopupContainer's
    // default-property content below) by id from this sibling binding
    // threw "ReferenceError: contentLoader is not defined" — likely an
    // id-scoping quirk through PopupContainer's `default property
    // alias content: contentWrapper.child`. Sidestepped entirely: a
    // plain property on root, updated imperatively from INSIDE
    // contentLoader's own declaration (where referencing its own
    // `item` is unambiguous), instead of read cross-branch by id.
    property bool contentReady: false

    OpenCloseOffset {
        id: motion
        opened: root.showPopup && root.contentReady
    }

    // Mask registration — see ShellState.activePopupItems. Exactly
    // mirrors showPopup, not the fade-out: closing means click-through
    // immediately, even while still visually fading for a bit longer.
    onShowPopupChanged: {
        if (showPopup)
            ShellState.registerPopup(root);
        else
            ShellState.unregisterPopup(root);
    }
    Component.onDestruction: ShellState.unregisterPopup(root)

    PopupContainer {
        id: container
        selfAnimated: false
        uiScale: root.uiScale
        // Was anchors.fill: parent + a y-translation — now sized to
        // its OWN natural full size always (never shrinks/squishes as
        // root's height animates) and pinned at y: 0. root's growing
        // height (the clip window) does the entire reveal; container
        // itself never moves or resizes, so nothing inside it gets
        // visually squashed mid-animation.
        width: implicitWidth
        height: implicitHeight
        y: 0

        DelayedUnloadLoader {
            id: contentLoader
            shown: root.showPopup
            asynchronousLoad: true
            sourceComponent: root.contentComponent
            onItemChanged: root.contentReady = item !== null
        }
    }
}
