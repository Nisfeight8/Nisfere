pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.core
import qs.services
import "components"
import "components/DockerManager"
import "components/Settings"
import "components/GitManager"
import "components/TabsComponent"
import "components/SearchComponent"

// Top-level content host for the Dashboard drawer — the single place
// that decides which of the 8 top-level components is on screen,
// driven entirely by ShellState.dashboardActiveComponent:
//
//   "tabs"       — info dashboard (TabsComponent)
//   "search"     — unified search/launcher (SearchComponent) — also
//                  covers the classic "app launcher" experience,
//                  scoped to the "apps" provider (browse mode until you
//                  type, same grid AppLauncherPanel already shows there)
//   "docker"     — Docker Manager
//   "sysmon"     — System Monitor
//   "settings"   — Shell & Hyprland settings
//   "screenshot" — capture mode picker (full/window/area/delay)
//   "record"     — screen recording mode picker + recording indicator
//   "git"        — per-repo git manager (status/stage/commit/push/pull)
//                  — unlike every other standalone tool here, needs to
//                  know WHICH repo; see ShellState.gitManagerRepoPath
//
// docker/sysmon/settings/screenshot/record/git used to live NESTED
// inside SearchComponent or a separate QuickActions bottom drawer —
// they're peers of "search" now instead, rendered directly here with
// no search-bar chrome at all. None of them know about each other or
// about search; this file is the only place that decides which one is
// showing. screenshot/record are deliberately small/compact (no
// anchors.fill on their own root — see their own header comments) —
// unlike docker/sysmon/settings/git, they're quick popup-style
// pickers, not persistent content-heavy tools, so the drawer shrinking
// to fit them is the intended look, not a bug.
//
// (There used to be a 4th standalone component here, "appLauncherFull"
// — a search-bar-less full app grid. Removed: it was a strict subset
// of "search" scoped to "apps", which already shows the exact same
// grid when the query is empty, PLUS lets you type — the search-bar-
// less version could never offer that. See ShellState.qml's own note
// on this for the full reasoning.)
Item {
    id: wrapper

    // Computed locally per-window via QsWindow — no prop-threading
    // needed from BaseDrawer/FooterDrawer down to here.
    readonly property real uiScale: Theme.scaleFor(QsWindow.window?.screen)

    implicitWidth: pageLoader.item?.implicitWidth ?? 0
    implicitHeight: pageLoader.item?.implicitHeight ?? 0

    readonly property var _componentMap: ({
            "tabs": tabsComp,
            "search": searchComp,
            "docker": dockerComp,
            "sysmon": sysmonComp,
            "settings": settingsComp,
            "screenshot": screenshotComp,
            "record": recordComp,
            "git": gitComp
        })

    Component {
        id: tabsComp
        TabsComponent {
            uiScale: wrapper.uiScale
        }
    }
    Component {
        id: searchComp
        SearchComponent {
            uiScale: wrapper.uiScale
        }
    }
    Component {
        id: dockerComp
        DockerManager {
            color: Theme.background
            uiScale: wrapper.uiScale
        }
    }
    Component {
        id: sysmonComp
        SystemMonitorTool {
            uiScale: wrapper.uiScale
        }
    }
    Component {
        id: settingsComp
        Settings {
            uiScale: wrapper.uiScale
        }
    }
    Component {
        id: screenshotComp
        ScreenshotPanel {
            uiScale: wrapper.uiScale
        }
    }
    Component {
        id: recordComp
        RecordPanel {
            uiScale: wrapper.uiScale
        }
    }
    Component {
        id: gitComp
        GitManager {
            uiScale: wrapper.uiScale
            // The one piece of per-instance state none of the other
            // standalone tools need — see ShellState.gitManagerRepoPath.
            repoPath: ShellState.gitManagerRepoPath
        }
    }

    AnimLoader {
        id: pageLoader
        anchors.fill: parent
        sourceComp: wrapper._componentMap[ShellState.dashboardActiveComponent] ?? tabsComp
    }
}
