pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "core"
import "panels"

// The Dashboard's Search page — visible whenever
// ShellState.dashboardActiveComponent === "search". Self-contained:
// owns the search bar + the results/drilldown loader for every
// genuine SEARCH PROVIDER (apps/wallpapers/colors/clipboard/ssh/git/
// commands) and the "@" provider-picker.
//
// The standalone top-level tools (appLauncherFull/docker/sysmon/
// settings) no longer live inside this file at all — they're peers of
// "search" itself now (see ShellState.dashboardActiveComponent),
// rendered directly by DashboardContent with no search-bar chrome.
// This file genuinely only ever deals with things that make sense to
// filter/search by typed text.
Item {
    id: root
    focus: true

    property real uiScale: 1.0

    implicitWidth: mainColumn.implicitWidth
    implicitHeight: mainColumn.implicitHeight

    readonly property var parsed: SearchProviders.parseQuery(ShellState.dashboardSearchText)
    readonly property string providerQuery: parsed.rest
    readonly property bool hasDrilldown: ShellState.dashboardSearchHasDrilldown

    // Most providers just update which one search is scoped to. Two
    // exceptions redirect away from rendering anything here at all:
    //   "standalone" — a real top-level component to show instead
    //                  (docker/sysmon/settings) — see ShellState.
    //   "immediate"  — no component at all, just run the provider's
    //                  own action() and close (e.g. colorpicker) —
    //                  was previously a search() result you still had
    //                  to click/Enter on for nothing to actually pick.
    onParsedChanged: {
        const p = SearchProviders.findById(parsed.providerId);
        if (p && p.standalone) {
            ShellState.openDashboardComponent(ShellState.activeScreenName, p.id);
            return;
        }
        if (p && p.immediate) {
            ShellState.closeDashboard();
            p.action();
            return;
        }
        // Fires once when you actually ARRIVE at a new provider scope
        // (not on every keystroke while still inside the same one) —
        // for providers whose backing data needs an explicit "wake up
        // and fetch" (e.g. docker's own refresh timer only runs while
        // the full Docker Manager GUI happens to be open, so arriving
        // at "@containers" without ever having opened that GUI this
        // session would otherwise show stale/empty data). Compared
        // against the CURRENT (not-yet-updated) dashboardSearchProviderId
        // — the write below is deferred, so at this point it's still
        // whatever provider we're actually leaving.
        if (p && p.onScopeEnter && parsed.providerId !== ShellState.dashboardSearchProviderId)
            p.onScopeEnter();
        // Deferred — see comment: writing this synchronously during
        // SearchComponent's initial construction can race with
        // searchLoader.sourceComp's own first evaluation (which also
        // depends on dashboardSearchProviderId), triggering a QML binding
        // loop that silently keeps the STALE pre-write value instead of
        // picking up the correction. Qt.callLater pushes the write to the
        // next event-loop tick, after construction has fully settled, so
        // sourceComp's dependency update lands cleanly instead of
        // re-entering its own in-progress evaluation.
        Qt.callLater(() => {
            ShellState.dashboardSearchProviderId = parsed.providerId;
        });
    }

    // Local map from providerId -> this file's own Component ids.
    // Previously this lived as a mutated `.component` field written
    // onto SearchProviders' provider objects in Component.onCompleted
    // — but SearchProviders' providers array is a plain `var` array
    // (no change signal), so that first mutation could lose a race
    // against sourceComp's first evaluation, patched over with a
    // providersReady flag. Keeping the mapping local instead removes
    // the race entirely: these are sibling ids in THIS file, valid
    // from object-tree construction, before any binding ever runs —
    // no "not ready yet" state can exist.
    readonly property var _componentMap: ({
            "apps": appsComponent,
            "wallpapers": wallpapersComponent,
            "colors": colorsComponent,
            "clipboard": clipboardComponent,
            "files": filesComponent,
            "providerSuggest": providerSuggestComponent
        })

    function _resultsComponentFor(providerId) {
        if (providerId === "apps" && root.providerQuery !== "")
            return searchResultsComp;
        const result = root._componentMap[providerId] ?? searchResultsComp;
        return result;
    }
    // A single optional drilldown within search results — today only
    // "providerPicker" (the button next to the search field), rendered
    // directly since there's no PanelStackHost switch to route through
    // anymore. Add another `if` here once a real git/ssh drilldown view
    // exists — no dispatcher component needed for just two or three
    // cases.
    function _drilldownComponentFor(panelId) {
        if (panelId === "providerPicker")
            return drilldownProviderPickerComponent;
        return null;
    }

    Component {
        id: appsComponent
        AppLauncherPanel {
            id: appsPanelInline
            uiScale: root.uiScale
            function activateSelected() {
                if (appsPanelInline.launchSelected())
                    ShellState.closeDashboard();
            }
        }
    }
    Component {
        id: wallpapersComponent
        WallpapersPanel {
            searchText: root.providerQuery
            uiScale: root.uiScale
        }
    }
    Component {
        id: colorsComponent
        ColorsPanel {
            searchText: root.providerQuery
            uiScale: root.uiScale
        }
    }
    Component {
        id: clipboardComponent
        ClipboardPanel {
            searchText: root.providerQuery
            uiScale: root.uiScale
        }
    }
    Component {
        id: filesComponent
        FileSearchPanel {
            searchText: root.providerQuery
            uiScale: root.uiScale
        }
    }
    Component {
        id: searchResultsComp
        GenericResultsList {
            uiScale: root.uiScale
        }
    }
    Component {
        id: providerSuggestComponent
        ProviderPicker {
            filterQuery: root.providerQuery
            uiScale: root.uiScale
        }
    }
    Component {
        id: drilldownProviderPickerComponent
        ProviderPicker {
            uiScale: root.uiScale
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 15 * root.uiScale

        DashboardSearchBar {
            id: dashboardSearchBar
            Layout.fillWidth: true
            uiScale: root.uiScale
            onEscapePressed: ShellState.closeDashboardSearch()
            onKeyPressed: e => {
                if (e.key !== Qt.Key_Up && e.key !== Qt.Key_Down && e.key !== Qt.Key_Left && e.key !== Qt.Key_Right)
                    return;
                if (searchLoader.item && searchLoader.item.navigate) {
                    const delta = (e.key === Qt.Key_Up || e.key === Qt.Key_Left) ? -1 : 1;
                    searchLoader.item.navigate(delta);
                }
            }
            onAccepted: {
                if (searchLoader.item && searchLoader.item.activateSelected)
                    searchLoader.item.activateSelected();
            }
        }

        AnimLoader {
            id: searchLoader
            Layout.fillWidth: true
            sourceComp: {
                const comp = root.hasDrilldown ? root._drilldownComponentFor(ShellState.dashboardSearchDrilldownPanelId) : root._resultsComponentFor(ShellState.dashboardSearchProviderId);
                return comp;
            }
        }
    }

    Keys.onEscapePressed: ShellState.closeDashboard()
}
