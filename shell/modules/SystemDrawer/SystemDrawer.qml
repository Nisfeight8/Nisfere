import QtQuick
import qs.core
import qs.services

BaseDrawer {
    id: root
    z: 10
    sidePanelMode: true
    edge: Qt.LeftEdge
    screenOffset: Theme.scaledBarHeight(root.screen)
    openedRequest: ShellState.systemDrawerOpened
    minPanelWidth: 450 * Theme.scaleFor(root.screen)
    onCloseRequest: ShellState.systemDrawerOpened = false
    onOpenedChanged: if (opened)
        UpdateService.loadCached()

    contentComponent: Component {
        SystemDrawerContent {}
    }
}
