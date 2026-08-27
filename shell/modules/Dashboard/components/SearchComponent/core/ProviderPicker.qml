import QtQuick
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    property string filterQuery: ""

    readonly property var allProviders: [
        {
            id: "apps",
            label: "Apps",
            icon: "layout-grid",
            keyword: ""
        }
    ].concat(SearchProviders.keywordProviders)

    readonly property var results: {
        const q = root.filterQuery.toLowerCase();
        const list = q === "" ? root.allProviders : root.allProviders.filter(p => p.label.toLowerCase().includes(q) || p.keyword.toLowerCase().includes(q));
        return list.map(p => ({
                    id: p.id,
                    title: p.label,
                    subtitle: p.keyword !== "" ? p.keyword : "",
                    icon: p.icon
                }));
    }

    implicitWidth: resultsList.implicitWidth
    implicitHeight: resultsList.implicitHeight

    function navigate(delta) {
        resultsList.navigate(delta);
    }
    function activateSelected() {
        resultsList.activateSelected();
    }

    ResultsListView {
        id: resultsList
        uiScale: root.uiScale
        anchors.fill: parent
        results: root.results
        emptyText: "No matching providers"
        maxListHeight: 6 * rowHeight // cap at ~6 visible rows
        onResultActivated: (r, index) => {
            const p = SearchProviders.findById(r.id);
            if (!p)
                return;
            ShellState.dashboardSearchText = p.keyword !== "" ? p.keyword + " " : "";
            ShellState.dashboardSearchProviderId = p.id;
            ShellState.closeSearchDrilldown();
        }
    }
}
