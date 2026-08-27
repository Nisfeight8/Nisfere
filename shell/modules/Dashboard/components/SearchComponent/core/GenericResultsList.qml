import QtQuick
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    readonly property var parsed: SearchProviders.parseQuery(ShellState.dashboardSearchText)
    readonly property var activeProvider: SearchProviders.findById(parsed.providerId)
    readonly property string providerQuery: parsed.rest

    readonly property bool isUnified: root.activeProvider && root.activeProvider.id === "apps"

    readonly property var results: {
        if (root.isUnified)
            return SearchProviders.searchAll(root.providerQuery);
        return (root.activeProvider && root.activeProvider.search) ? root.activeProvider.search(root.providerQuery) : [];
    }

    // Only "containers" has async loading today (reads from
    // DockerService, whose data arrives from the daemon) — every
    // other provider's search() is synchronous/local, nothing to wait
    // on. Direct provider-id check + DockerService.loading, both real
    // property reads inside this actual QML binding, so it's fully
    // reactive without needing anything added to the provider schema
    // itself.
    readonly property bool providerLoading: root.activeProvider && root.activeProvider.id === "containers" ? DockerService.loading : false

    implicitWidth: listView.implicitWidth
    implicitHeight: listView.implicitHeight

    function navigate(delta) {
        listView.navigate(delta);
    }
    function activateSelected() {
        listView.activateSelected();
    }

    ResultsListView {
        id: listView
        uiScale: root.uiScale
        anchors.fill: parent
        results: root.results
        loading: root.providerLoading
        loadingText: "Loading..."
        maxListHeight: 360 * root.uiScale
        onResultActivated: (r, index) => {
            const provider = SearchProviders.findById(r.providerId ?? root.activeProvider.id);
            if (!provider)
                return;
            if (r.panelId) {
                ShellState.openSearchDrilldown(r.panelId, provider.id);
            } else if (provider.pushOnActivate) {
                ShellState.openSearchDrilldown(provider.id, provider.id);
            } else {
                ShellState.closeDashboard();
            }
            if (r.action)
                r.action();
        }
    }
}
