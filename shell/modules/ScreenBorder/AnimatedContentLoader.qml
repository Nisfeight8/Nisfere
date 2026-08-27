import QtQuick
import qs.core

FocusScope {
    id: root

    property bool shouldBeActive: false
    property Component sourceComponent
    // Was 300 — shorter than motion's own 500ms DefaultSpatial curve,
    // so content was being destroyed ~200ms before the close animation
    // visually finished (same bug found via BarPopup/ActiveWindow).
    property int unloadDelay: AnimTokens.durationDefaultSpatial + 50

    // Was root's own property, driven by two inline Anim blocks —
    // now sourced from the shared OpenCloseOffset engine (see
    // core/anim/OpenCloseOffset.qml). Kept as a readonly alias so any
    // existing external `.offset` reads keep working unchanged.
    readonly property alias offset: motion.offset

    visible: root.offset < 1.0
    opacity: 1.0 - root.offset
    scale: 0.95 + (0.05 * (1.0 - root.offset))
    transformOrigin: Item.Center

    OpenCloseOffset {
        id: motion
        opened: root.shouldBeActive
    }

    // Same keep-alive-during-close-animation logic as BarPopup and
    // DrawerContentHost — see DelayedUnloadLoader.qml.
    DelayedUnloadLoader {
        id: contentLoader
        anchors.fill: parent
        shown: root.shouldBeActive
        unloadDelay: root.unloadDelay
        sourceComponent: root.sourceComponent
    }
}
