import QtQuick
import Quickshell.Widgets
import qs.core
import qs.services

// Hosts the drawer's content: wraps it in a WrapperItem (for directional
// margins), loads/unloads it based on `opened`, and reports the loaded
// content's implicit size upward so the parent can size the window.
// Handles the "keep loaded briefly after close, then gc()" lifecycle.
Item {
    id: root

    property Component contentComponent
    property bool opened: false
    property bool preload: false

    property bool asynchronousLoad: true
    
    property int unloadDelay: ShellState.drawerDelayInterval

    property real marginTop: 0
    property real marginBottom: 0
    property real marginLeft: 0
    property real marginRight: 0

    readonly property real contentImplicitWidth: contentLoader.item?.implicitWidth ?? 0
    readonly property real contentImplicitHeight: contentLoader.item?.implicitHeight ?? 0

    signal contentSizeChanged

    onOpenedChanged: {
        if (opened)
            unloadTimer.stop();
        else
            unloadTimer.restart();
    }

    Timer {
        id: unloadTimer
        interval: root.unloadDelay
        onTriggered: gc()
    }

    WrapperItem {
        id: contentWrapper
        anchors.fill: parent
        topMargin: root.marginTop
        bottomMargin: root.marginBottom
        leftMargin: root.marginLeft
        rightMargin: root.marginRight

        Loader {
            id: contentLoader
            active: root.preload || root.opened || unloadTimer.running
            asynchronous: root.asynchronousLoad
            sourceComponent: root.contentComponent

            onItemChanged: root.contentSizeChanged()
        }
    }

    Connections {
        target: contentLoader.item
        function onImplicitWidthChanged() {
            root.contentSizeChanged();
        }
        function onImplicitHeightChanged() {
            root.contentSizeChanged();
        }
    }
}
