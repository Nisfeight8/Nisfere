pragma ComponentBehavior: Bound
import QtQuick
import qs.core
import qs.services

FooterDrawer {
    id: root
    z: 10
    edge: Qt.TopEdge
    edgeMargin: 0
    screenOffset: Theme.scaledBarHeight(root.screen)
    minPanelWidth: 250
    toggleOnHover: false
    openedRequest: ShellState.dashboardOpened

    onCloseRequest: ShellState.closeDashboard()
    footerHeight: 36 * Theme.scaleFor(root.screen)
    footerComponent: Component {
        DashboardFooter {
        }
    }
    contentComponent: Component {
        DashboardContent {
            id: content
        }
    }
    readonly property Item footerMaskTarget: (footerLoadedItem && footerLoadedItem.contentRow) ? footerLoadedItem.contentRow : footerItem
}
