import QtQuick
import qs.services
// Drop-in replacement for a bare `Loader` that keeps the loaded item
// alive for `unloadDelay` ms after `shown` goes false — long enough
// for whatever close/fade animation the CALLER runs on its own
// opacity/position to actually show the content disappearing, instead
// of the content vanishing instantly while an empty container fades.
//
// Same pattern DrawerContentHost.qml already uses internally for
// drawers; extracted here so BarPopup/AnimatedContentLoader (and
// anything else with a show/hide fade over lazy-loaded content) don't
// have to re-derive it from scratch.
//
// Sizing follows the SAME two-channel split as DrawerContentHost:
//   - implicitWidth/implicitHeight report the loaded content's own
//     implicit size UPWARD, for a caller that wants to size itself
//     AROUND this (e.g. a WrapperItem computing margins).
//   - this component's own ACTUAL width/height are NEVER self-bound
//     to those — whoever contains it decides the actual size, exactly
//     like a bare Loader leaves that decision to its container
//     (anchors.fill: parent, or a WrapperItem/MarginWrapperManager
//     setting it directly). Binding actual size to the implicit
//     values here too was the earlier bug: it fought with an external
//     `anchors.fill: parent`, leaving the item pinned small in the
//     top-left corner instead of filling its region.
Item {
    id: root

    property Component sourceComponent
    property bool shown: false
    property bool asynchronousLoad: true
    property int unloadDelay: ShellState.drawerDelayInterval

    readonly property alias item: loader.item

    implicitWidth: loader.item?.implicitWidth ?? 0
    implicitHeight: loader.item?.implicitHeight ?? 0

    signal contentSizeChanged

    onShownChanged: {
        if (shown)
            unloadTimer.stop();
        else
            unloadTimer.restart();
    }

    Timer {
        id: unloadTimer
        interval: root.unloadDelay
        onTriggered: gc()
    }

    Loader {
        id: loader
        anchors.fill: parent
        active: root.shown || unloadTimer.running
        asynchronous: root.asynchronousLoad
        sourceComponent: root.sourceComponent

        onItemChanged: root.contentSizeChanged()
    }

    Connections {
        target: loader.item
        function onImplicitWidthChanged() {
            root.contentSizeChanged();
        }
        function onImplicitHeightChanged() {
            root.contentSizeChanged();
        }
    }
}
