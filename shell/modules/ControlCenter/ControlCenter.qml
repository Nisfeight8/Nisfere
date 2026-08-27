import QtQuick
import qs.core
import qs.services

BaseDrawer {
    id: root
    z: 10
    cornerMode: true
    edge: Qt.RightEdge
    screenOffset: Theme.scaledBarHeight(root.screen)
    openedRequest: ShellState.controlCenterOpened

    // Scaled so the drawer's minimum footprint stays resolution-
    // appropriate rather than pinned to a 1080p-tuned size — same
    // reasoning as TabsComponent's minContentWidth/Height.
    minPanelWidth: 480 * Theme.scaleFor(root.screen)
    minPanelHeight: 300 * Theme.scaleFor(root.screen)
    toggleOnHover: false

    onCloseRequest: ShellState.controlCenterOpened = false

    contentComponent: Component {
        ControlCenterContent {}
    }
}
