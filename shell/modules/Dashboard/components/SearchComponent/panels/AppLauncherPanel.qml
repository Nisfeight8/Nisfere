import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services
import "../core"

Item {
    id: root
    property real uiScale: 1.0
    implicitWidth: 640 * uiScale
    implicitHeight: 400 * uiScale

    function _findApp(name) {
        const apps = DesktopEntries.applications.values;
        for (let i = 0; i < apps.length; i++)
            if (apps[i].name === name)
                return apps[i];
        return null;
    }

    readonly property var mainCategories: ["AudioVideo", "Audio", "Video", "Development", "Education", "Game", "Graphics", "Network", "Office", "Science", "Settings", "System", "Utility",]
    readonly property var categoryIcons: ({
            "AudioVideo": "music",
            "Audio": "music",
            "Video": "video",
            "Development": "code",
            "Education": "graduation-cap",
            "Game": "gamepad-2",
            "Graphics": "image",
            "Network": "network",
            "Office": "file-text",
            "Science": "flask-conical",
            "Settings": "settings",
            "System": "cpu",
            "Utility": "wrench"
        })

    readonly property var allAppsArray: DesktopEntries.applications.values.slice().sort((a, b) => a.name.localeCompare(b.name))

    readonly property var favoriteApps: AppUsageService.favorites.map(n => root._findApp(n)).filter(a => a !== null)
    readonly property var recentApps: AppUsageService.recentNames.map(n => root._findApp(n)).filter(a => a !== null)
    readonly property var mostUsedApps: AppUsageService.mostUsedNames.map(n => root._findApp(n)).filter(a => a !== null)

    readonly property var presentCategories: {
        const set = new Set();
        for (const app of root.allAppsArray)
            for (const cat of (app.categories || []))
                if (root.mainCategories.indexOf(cat) !== -1)
                    set.add(cat);
        return root.mainCategories.filter(c => set.has(c));
    }

    readonly property var sideMenuModel: {
        const base = [
            {
                icon: "layout-grid",
                title: "All Applications",
                key: "all"
            },
            {
                icon: "star",
                title: "Favorites",
                key: "favorites"
            },
            {
                icon: "trending-up",
                title: "Most Used",
                key: "mostUsed"
            },
            {
                icon: "clock",
                title: "Recently",
                key: "recent"
            },
        ];
        const catItems = root.presentCategories.map(c => ({
                    icon: root.categoryIcons[c] || "shapes",
                    title: c,
                    key: "category:" + c
                }));
        return base.concat(catItems);
    }

    readonly property var currentTabApps: {
        const tab = ShellState.dashboardSearchAppsSubTab;
        if (tab.startsWith("category:")) {
            const cat = tab.substring("category:".length);
            return root.allAppsArray.filter(a => (a.categories || []).indexOf(cat) !== -1);
        }
        switch (tab) {
        case "favorites":
            return root.favoriteApps;
        case "mostUsed":
            return root.mostUsedApps;
        case "recent":
            return root.recentApps;
        default:
            return root.allAppsArray;
        }
    }

    readonly property var results: root.currentTabApps.map(a => DesktopEntryService.toResultRow(a))

    function launchSelected() {
        const r = resultsList.results[resultsList.selectedIndex];
        if (r && r.action) {
            r.action();
            return true;
        }
        return false;
    }
    function navigate(delta) {
        resultsList.navigate(delta);
    }
    function activateSelected() {
        resultsList.activateSelected();
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 16 * root.uiScale

        SideMenu {
            Layout.fillHeight: true
            // Same cap-with-floor pattern as Productivity.qml's
            // SideMenu — prevents it from eating a disproportionate
            // share of width on a narrow screen (25% cap), while never
            // shrinking below a legible minimum (140*uiScale floor).
            Layout.preferredWidth: Math.max(170 * root.uiScale, Math.min(implicitWidth, rowLayout.width * 0.25))
            menuModel: root.sideMenuModel
            currentIndex: root.sideMenuModel.findIndex(m => m.key === ShellState.dashboardSearchAppsSubTab)
            uiScale: root.uiScale
            onTabClicked: idx => {
                ShellState.dashboardSearchAppsSubTab = root.sideMenuModel[idx].key;
            }
        }

        // ── List area ────────────────────────────────────────────
        ResultsListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            uiScale: root.uiScale
            results: root.results
            emptyText: "Nothing here yet"
            maxListHeight: 400 * root.uiScale

            onResultActivated: (r, index) => {
                if (r.action)
                    r.action();
                ShellState.closeDashboard();
            }
        }
    }
}
