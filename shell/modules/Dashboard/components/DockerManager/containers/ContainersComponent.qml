import QtQuick
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    anchors.fill: parent

    // Exactly 2 states (list / details for the currently-selected
    // container) — DockerService.isViewingDetails already IS that
    // state, reactively. Was a StackView doing a Qt.resolvedUrl()
    // dynamic push driven by a navigateToDetails signal — replaced
    // with the same AnimLoader crossfade pattern used everywhere else
    // in this shell (DashboardContent, SearchComponent), driven
    // directly off the existing flag. No separate "which page" state
    // needed, no signal listener needed — StackView's push/pop
    // history was solving a problem this 2-state toggle doesn't have.
    Component {
        id: listComp
        ContainerListPage {
            uiScale: root.uiScale
        }
    }
    Component {
        id: detailsComp
        ContainerDetailsPage {
            uiScale: root.uiScale
        }
    }

    AnimLoader {
        anchors.fill: parent
        sourceComp: DockerService.isViewingDetails ? detailsComp : listComp
    }
}
