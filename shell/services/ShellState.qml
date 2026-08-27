pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell

import QtQuick
import qs.core
import qs.services

Singleton {
    id: root

    // Which screen "owns" whichever UI is currently open — every
    // per-screen drawer/loader additionally gates on
    // `screen.name === activeScreenName`, so hovering an edge on one
    // screen doesn't pop the same UI up on every screen at once.
    property string activeScreenName: ""

    // For IPC-triggered opens (keybinds), which don't have a "which
    // screen did this come from" of their own.
    readonly property string focusedScreenName: HyprlandData.focusedMonitor?.name ?? ""

    property bool isLocked: false
    property bool powerMenuOpened: false

    property bool terminalOpened: false

    property bool controlCenterOpened: false
    property int controlCenterPageIndex: 0
    property bool systemDrawerOpened: false
    property bool dockOpened: false

    // ── Dashboard ────────────────────────────────────────────────────
    // FULL REFACTOR (see chat) — replaces the old
    // dashboardSearchCompActive bool + dashboardSearchCompPanelStack
    // array. The drawer shows exactly ONE top-level component at a
    // time, named here explicitly instead of inferred from a
    // combination of flags:
    //
    //   "tabs"            — info dashboard (overview/media/weather/
    //                       notifications/productivity)
    //   "search"          — unified search/launcher experience (also
    //                       covers the classic "app launcher" —
    //                       scoped to the "apps" provider, see
    //                       openDashboardSearch/openWallpapers etc.)
    //   "docker"     — Docker Manager
    //   "sysmon"     — System Monitor
    //   "settings"   — Shell & Hyprland settings
    //   "screenshot" — capture mode picker (full/window/area/delay)
    //   "record"     — screen recording mode picker + recording indicator
    //
    // docker/sysmon/settings/screenshot/record are reached FROM search
    // (typing a keyword, or the "@" provider picker) but don't live
    // NESTED inside search's own state once open — they're standalone,
    // full-screen top-level components, same tier as "tabs"/"search"
    // themselves. There is deliberately no "back" — the only way out
    // of any of them is closeDashboard(), which always resets back to
    // "tabs" for next time. This is a simplification from the previous
    // design (which nested them under search + a push/pop panel
    // stack) — see chat for the reasoning.
    //
    // (There used to be a 4th standalone component, "appLauncherFull" —
    // a search-bar-less full app grid with side-menu categories. Removed
    // entirely: it was a strict subset of what "search" scoped to
    // "apps" already does — same browse-mode grid when the query is
    // empty, PLUS the ability to type and get results, which the
    // search-bar-less version could never offer. No use case lost.)
    property bool dashboardOpened: false
    property string dashboardActiveComponent: "tabs"
    property int drawerDelayInterval: AnimTokens.durationDefaultSpatial + 50

    // ── "tabs" component state ────────────────────────────────────────
    property int dashboardTabsCurrentTab: 0
    property int dashboardTabsCurrentProductivityTab: 0

    // ── "search" component state ───────────────────────────────────────
    // Deliberately PERSISTENT across close/reopen — lives here instead
    // of inside the component itself so it survives DrawerContentHost's
    // unload-on-close timer destroying/recreating the loaded item.
    property string dashboardSearchText: ""
    property string dashboardSearchProviderId: "apps" // mirrors SearchProviders.parseQuery(dashboardSearchText).providerId — written by SearchComponent, read by others (e.g. the search bar's provider icon)
    property string dashboardSearchAppsSubTab: "all" // sub-tab inside the browse-mode AppLauncherPanel (All/Favorites/Recent/category:X)

    // A single optional drilldown WITHIN search results — e.g.
    // selecting a git repo result opens a repo-browser view, still
    // inside the search context (editing the query backs out of it,
    // same as before). Was an array (dashboardSearchCompPanelStack)
    // that nothing ever actually pushed more than one level deep onto
    // — every consumer only ever read the top entry. A scalar says the
    // same thing without pretending to support depths this shell never
    // uses; if genuine multi-level drilldown is ever needed, upgrade
    // back to a stack THEN, not preemptively now.
    property string dashboardSearchDrilldownPanelId: "" // "" = none
    property string dashboardSearchDrilldownProviderId: ""
    readonly property bool dashboardSearchHasDrilldown: dashboardSearchDrilldownPanelId !== ""

    function openSearchDrilldown(panelId, providerId) {
        dashboardSearchDrilldownPanelId = panelId;
        dashboardSearchDrilldownProviderId = providerId;
    }
    function closeSearchDrilldown() {
        dashboardSearchDrilldownPanelId = "";
        dashboardSearchDrilldownProviderId = "";
    }

    // ── Dashboard/ControlCenter focus & layer intent ─────────────────
    // Screen-agnostic: describes what the *currently active* dashboard
    // / control-center state wants, without per-screen gating.
    // ScreenBorder ANDs these with its own
    // `activeScreenName === screen.name` check per instance.
    //
    // One lookup table instead of an ever-growing boolean expression —
    // adding a new standalone Dashboard component that needs
    // Exclusive/OnDemand focus means adding ONE entry here, not
    // editing a hand-written `||` chain in ScreenBorder.
    readonly property var _dashboardFocusModeByComponent: ({
            "tabs": "none",
            "search": "exclusive",
            "docker": "onDemand",
            "sysmon": "onDemand",
            "settings": "onDemand",
            "screenshot": "exclusive",
            "record": "exclusive",
            "git": "onDemand"
        })

    readonly property bool dashboardWantsExclusiveFocus: dashboardOpened && root._dashboardFocusModeByComponent[dashboardActiveComponent] === "exclusive"

    // Tabs-mode "productivity" tab (index 4, sub-tab 0) is the one
    // TabsComponent view that needs OnDemand focus + Overlay layer
    // even though "tabs" as a whole normally needs neither — kept as
    // its own explicit clause since it's a sub-state of "tabs"
    // specifically, not a peer of the top-level components above.
    readonly property bool dashboardWantsOnDemandFocus: dashboardOpened && (root._dashboardFocusModeByComponent[dashboardActiveComponent] === "onDemand" || (dashboardActiveComponent === "tabs" && dashboardTabsCurrentTab === 4 && dashboardTabsCurrentProductivityTab === 0))

    readonly property bool dashboardWantsOverlayLayer: dashboardWantsExclusiveFocus || dashboardWantsOnDemandFocus

    // ControlCenter page 1 has a focusable field (e.g. wifi password) —
    // wants OnDemand focus and the Overlay layer, never Exclusive.
    readonly property bool controlCenterWantsOverlayLayer: controlCenterOpened && controlCenterPageIndex === 1
    readonly property bool controlCenterWantsOnDemandFocus: controlCenterWantsOverlayLayer

    // ── Open/close ───────────────────────────────────────────────────

    // Opens the drawer showing whichever component was last active —
    // does NOT force a mode switch. This is what the bar clock/hover
    // edge should call: "just open the dashboard as I left it".
    function openDashboard(screenName) {
        activeScreenName = screenName;
        dashboardOpened = true;
    }

    // Components that are "extended-use tools" (you're doing ongoing
    // work in them, like a real app) rather than one-shot actions.
    readonly property var _dashboardResumableComponents: ["docker", "sysmon", "settings", "git"]

    // Which resumable tool (if any) is remembered as "still open in
    // the background" — "" means none. Deliberately SEPARATE from
    // dashboardActiveComponent (what's rendered right now): navigating
    // to Tabs/Search/anything else changes dashboardActiveComponent
    // freely without touching this, so e.g. clicking the bar clock to
    // glance at Tabs doesn't lose your Docker session — only an
    // explicit exit (closeResumableComponent from inside the tool, or
    // forgetResumableComponent from the bar's right-click) clears it.
    property string dashboardResumableComponent: ""

    // For bar widgets/shortcuts that want to show "you left something
    // open" (e.g. a small indicator, or a one-click jump back into it).
    readonly property bool dashboardHasResumableComponentActive: dashboardResumableComponent !== ""

    // Called from INSIDE a resumable tool's own UI (e.g. an "X" in its
    // top-right corner) — you're actively done with it: forgets it AND
    // closes the whole dashboard, since you were looking at it when
    // you chose to exit.
    function closeResumableComponent() {
        dashboardResumableComponent = "";
        closeDashboard();
    }

    // Called from the bar indicator's right-click — dismiss the
    // "still open" reminder WITHOUT touching whatever the dashboard
    // currently shows (you might be looking at Tabs/Search/something
    // else entirely when you decide you're done with the backgrounded
    // tool).
    function forgetResumableComponent() {
        dashboardResumableComponent = "";
    }

    // The ONLY way out of any Dashboard component via the normal close
    // path — always resets back to "tabs" eventually. Does NOT touch
    // dashboardResumableComponent — that's tracked independently now
    // (see above), so closing/reopening the dashboard casually never
    // silently drops or restores a backgrounded tool by accident.
    //
    // dashboardActiveComponent reset is DEFERRED (via
    // _closeTabsResetTimer below) rather than immediate: setting it
    // synchronously here made DashboardContent's AnimLoader start its
    // own fade-swap (e.g. Docker -> Tabs) at the exact same moment the
    // whole drawer starts sliding/fading closed — two animations
    // fighting each other. Waiting until the drawer's own close motion
    // has plausibly finished means the swap happens invisibly, after
    // the drawer is already gone.
    function closeDashboard() {
        dashboardOpened = false;
        _closeTabsResetTimer.restart();
    }

    Timer {
        id: _closeTabsResetTimer
        // Was a hardcoded 250ms guess — now matches the drawer's
        // actual close-slide duration exactly (see BaseDrawer/
        // FooterDrawer's own AnimTokens.durationDefaultSpatial + 50
        // usage), so this can never silently drift out of sync with
        // it again.
        interval: drawerDelayInterval
        onTriggered: {
            dashboardActiveComponent = "tabs";
            // Was immediate inside closeDashboard() itself — cleared
            // the search text (and any drilldown) synchronously while
            // the drawer was still visually fading/sliding closed and
            // the results list was still on screen. providerId stayed
            // the same but the query text momentarily became "",
            // so GenericResultsList briefly recomputed against an
            // EMPTY query (e.g. "apps".search("") — every app,
            // alphabetically) before the drawer actually finished
            // closing — visible as a flash of different results right
            // as you activated one. Same class of race as the
            // component-swap fix above, same fix: defer until the
            // close motion has plausibly finished.
            dashboardSearchText = "";
            closeSearchDrilldown();
        }
    }

    function toggleDashboard(screenName) {
        if (dashboardOpened && activeScreenName === screenName)
            closeDashboard();
        else
            openDashboard(screenName);
    }

    // Forces the drawer into "tabs" — e.g. clicking a specific tab
    // shortcut, or backing out of search entirely.
    function openDashboardTabs(screenName) {
        activeScreenName = screenName;
        dashboardOpened = true;
        dashboardActiveComponent = "tabs";
        dashboardSearchText = "";
        closeSearchDrilldown();
    }

    function toggleDashboardTabs(screenName) {
        if (dashboardOpened && activeScreenName === screenName && dashboardActiveComponent === "tabs")
            closeDashboard();
        else
            openDashboardTabs(screenName);
    }

    // Same as toggleDashboardTabs, but for a bar widget that wants to
    // jump straight to a SPECIFIC tab (e.g. the clock widget's
    // notification bell / media icon) — closes only if the dashboard
    // is already open AND already showing exactly that tab; otherwise
    // switches to it. Plain toggleDashboardTabs()-then-set-tab-after
    // would close the dashboard instead of switching tabs whenever it
    // was already open showing something else (e.g. Search).
    function toggleDashboardTab(screenName, tabIndex) {
        if (dashboardOpened && activeScreenName === screenName && dashboardActiveComponent === "tabs" && dashboardTabsCurrentTab === tabIndex)
            closeDashboard();
        else {
            dashboardTabsCurrentTab = tabIndex;
            openDashboardTabs(screenName);
        }
    }

    // Generic entry point into "search" — optionally pre-scoped to a
    // specific provider by simulating that provider's own keyword
    // being typed (the same mechanism SearchProviders.parseQuery
    // already reads from typed text — no separate "programmatically
    // scoped" code path needed anywhere downstream). Leaves
    // dashboardSearchText untouched when no providerId is given (e.g.
    // the footer's plain search icon), same as before.
    //
    // This is also the IPC/shortcut entry point for anything that's a
    // SEARCH PROVIDER (wallpapers/colors/clipboard/ssh/git/apps) — see
    // the named convenience wrappers below. Standalone top-level tools
    // (docker/sysmon/settings) are NOT providers in this sense and use
    // openDashboardComponent instead.
    function openDashboardSearch(screenName, providerId) {
        activeScreenName = screenName;
        dashboardOpened = true;
        dashboardActiveComponent = "search";
        closeSearchDrilldown();
        // Only touches dashboardSearchText when a providerId is
        // actually given — leaves it untouched otherwise. When one IS
        // given, this is a SINGLE write, not "" followed immediately
        // by the real keyword — two separate assignments fire two
        // separate change notifications in QML (consecutive writes to
        // the same property aren't batched), and anything reactively
        // watching dashboardSearchText (SearchComponent's parsed)
        // would briefly re-evaluate against the empty string in
        // between. Concretely: opening "@wp" via shortcut was
        // flashing AppLauncherPanel (providerId "apps" for that
        // momentary empty text) before landing on the wallpapers panel.
        if (providerId !== undefined) {
            const p = SearchProviders.findById(providerId);
            dashboardSearchText = (p && p.keyword !== "") ? p.keyword + " " : "";
        }
    }

    // ── Named convenience wrappers — the IPC/shortcut-facing API for
    // each search provider that makes sense to jump straight into.
    // Add one line here per provider that should be directly
    // shortcut-able; no other state to manage per-provider.
    function openWallpapers(screenName) {
        openDashboardSearch(screenName, "wallpapers");
    }
    function openColors(screenName) {
        openDashboardSearch(screenName, "colors");
    }
    function openClipboard(screenName) {
        openDashboardSearch(screenName, "clipboard");
    }
    function openSsh(screenName) {
        openDashboardSearch(screenName, "ssh");
    }
    function openGit(screenName) {
        openDashboardSearch(screenName, "git");
    }
    function openColorPicker(screenName) {
        openDashboardSearch(screenName, "colorpicker");
    }

    // Generic toggle counterpart to openDashboardSearch — closes if
    // "search" is already showing scoped to exactly this same
    // provider on this same screen, otherwise opens it scoped there.
    // Mirrors toggleDashboardComponent's shape below, just checking
    // the provider too (search has one extra piece of state that the
    // standalone components don't).
    function toggleDashboardSearch(screenName, providerId) {
        if (dashboardOpened && activeScreenName === screenName && dashboardActiveComponent === "search" && (providerId === undefined || dashboardSearchProviderId === providerId)) {
            closeDashboardSearch();
        } else
            openDashboardSearch(screenName, providerId);
    }

    function closeDashboardSearch(screenName) {
        closeDashboard();
        dashboardSearchProviderId = '';
    }
    function toggleWallpapers(screenName) {
        toggleDashboardSearch(screenName, "wallpapers");
    }
    function toggleColors(screenName) {
        toggleDashboardSearch(screenName, "colors");
    }
    function toggleClipboard(screenName) {
        toggleDashboardSearch(screenName, "clipboard");
    }
    function toggleSsh(screenName) {
        toggleDashboardSearch(screenName, "ssh");
    }
    function toggleGit(screenName) {
        toggleDashboardSearch(screenName, "git");
    }
    function toggleColorPicker(screenName) {
        toggleDashboardSearch(screenName, "colorpicker");
    }

    // Generic entry point for a standalone top-level component
    // (docker/sysmon/settings, or any future one) — these carry no
    // scoping data of their own, unlike search providers, so this is
    // intentionally simpler than openDashboardSearch.
    function openDashboardComponent(screenName, componentId) {
        // If a closeDashboard() call from a split-second ago is still
        // waiting to reset dashboardActiveComponent back to "tabs" (see
        // _closeTabsResetTimer), cancel it — we're explicitly
        // navigating somewhere else right now, and without this the
        // stale timer would fire ~250ms later and snap whatever we're
        // about to open back to "tabs" out from under it. Concretely
        // hit by: a search result whose action opens a standalone
        // component (e.g. a git repo row opening the git manager) —
        // GenericResultsList calls closeDashboard() before running
        // that action.
        _closeTabsResetTimer.stop();
        activeScreenName = screenName;
        dashboardOpened = true;
        dashboardActiveComponent = componentId;
        if (_dashboardResumableComponents.indexOf(componentId) !== -1)
            dashboardResumableComponent = componentId;
    }
    function toggleDashboardComponent(screenName, componentId) {
        if (dashboardOpened && activeScreenName === screenName && dashboardActiveComponent === componentId)
            closeDashboard();
        else
            openDashboardComponent(screenName, componentId);
    }

    function openDocker(screenName) {
        openDashboardComponent(screenName, "docker");
    }
    function openSysmon(screenName) {
        openDashboardComponent(screenName, "sysmon");
    }
    function openSettings(screenName) {
        openDashboardComponent(screenName, "settings");
    }
    // Unlike docker/sysmon/settings (self-contained singleton tools),
    // the git manager needs to know WHICH repo — dashboardActiveComponent
    // alone doesn't carry that, so this sets both together. Opening a
    // DIFFERENT repo while one is already open just replaces the path
    // (this remembers the single LAST repo you were working in, not a
    // list of several).
    property string gitManagerRepoPath: ""
    function openGitManager(screenName, repoPath) {
        gitManagerRepoPath = repoPath;
        openDashboardComponent(screenName, "git");
    }
    function openScreenshot(screenName) {
        openDashboardComponent(screenName, "screenshot");
    }
    function openRecord(screenName) {
        openDashboardComponent(screenName, "record");
    }

    // ── Terminal drawer registry ──────────────────────────────────
    // Per-screen "run a command in THIS screen's terminal" — SearchProviders
    // (singleton, no idea which physical screen's drawer to use) needs a
    // way to reach the SPECIFIC per-screen TerminalDrawer content instance.
    // Minimal surface only ({ runCommand }), not the whole content Item.
    property var terminalDrawersByScreen: ({})

    function registerTerminalDrawer(screenName, api) {
        const copy = Object.assign({}, terminalDrawersByScreen);
        copy[screenName] = api;
        terminalDrawersByScreen = copy;
    }
    function unregisterTerminalDrawer(screenName) {
        if (!(screenName in terminalDrawersByScreen))
            return;
        const copy = Object.assign({}, terminalDrawersByScreen);
        delete copy[screenName];
        terminalDrawersByScreen = copy;
    }

    property int workspacesPerMonitor: ThemeState.shared.workspacesPerMonitor || 10
    property bool overviewOpen: false
    property int overviewRows: 2
    property int overviewColumns: workspacesPerMonitor / overviewRows
    property bool overviewPreviewsEnabled: true
    property bool overviewLivePreviews: false

    // ── Simple single-flag drawers ────────────────────────────────────
    // ControlCenter / SystemDrawer / Overview / PowerMenu all follow the
    // exact same open/close/toggle-with-same-screen-check shape. Rather
    // than four near-identical copies, one helper drives all four —
    // the public functions below stay as the explicit, readable API
    // callers use (and keep their own names for QML tooling/autocomplete),
    // they just delegate instead of repeating the pattern.
    function _openFlag(flagName, screenName) {
        activeScreenName = screenName;
        root[flagName] = true;
    }
    function _closeFlag(flagName) {
        root[flagName] = false;
    }
    function _toggleFlag(flagName, screenName) {
        if (root[flagName] && activeScreenName === screenName)
            _closeFlag(flagName);
        else
            _openFlag(flagName, screenName);
    }

    function openControlCenter(screenName) {
        _openFlag("controlCenterOpened", screenName);
    }
    function closeControlCenter() {
        _closeFlag("controlCenterOpened");
    }
    function toggleControlCenter(screenName) {
        _toggleFlag("controlCenterOpened", screenName);
    }

    function openSystemDrawer(screenName) {
        _openFlag("systemDrawerOpened", screenName);
    }
    function closeSystemDrawer() {
        _closeFlag("systemDrawerOpened");
    }
    function toggleSystemDrawer(screenName) {
        _toggleFlag("systemDrawerOpened", screenName);
    }
    function openTerminalDrawer(screenName) {
        _openFlag("terminalOpened", screenName);
    }
    function closeTerminalDrawer() {
        _closeFlag("terminalOpened");
    }
    function toggleTerminalDrawer(screenName) {
        _toggleFlag("terminalOpened", screenName);
    }

    function openDock(screenName) {
        _openFlag("dockOpened", screenName);
    }
    function closeDock() {
        _closeFlag("dockOpened");
    }
    function toggleDock(screenName) {
        _toggleFlag("dockOpened", screenName);
    }
    function openOverview(screenName) {
        _openFlag("overviewOpen", screenName);
    }
    function closeOverview() {
        _closeFlag("overviewOpen");
    }
    function toggleOverview(screenName) {
        _toggleFlag("overviewOpen", screenName);
    }

    function openPowerMenu(screenName) {
        _openFlag("powerMenuOpened", screenName);
    }
    function closePowerMenu() {
        _closeFlag("powerMenuOpened");
    }
    function togglePowerMenu(screenName) {
        _toggleFlag("powerMenuOpened", screenName);
    }

    // ── Bar popup registry ──────────────────────────────────────────
    // Which BarPopup Items currently need to be interactive — i.e.
    // included in ScreenBorder's mask (see chat: BarPopup switched
    // from its own separate PopupWindow surface to a plain Item
    // reparented into the already-live visualWindow, same approach
    // that's already smooth for Dashboard/ControlCenter/SystemDrawer.
    // A plain Item has no interactivity of its own outside whatever
    // the window's mask carves out for it — this list IS that carve-
    // out, built dynamically in ScreenBorder via a Repeater).
    //
    // A LIST, not a single item — multiple bar popups can genuinely
    // be open at once (e.g. the tray menu open via click while
    // separately hovering an unrelated widget's own popup).
    //
    // Registered the INSTANT a popup's showPopup becomes true,
    // unregistered the INSTANT it becomes false — deliberately NOT
    // tied to the popup's own fade-out animation. A closing popup
    // becomes click-through immediately rather than staying
    // interactive for the whole fade — concretely, this is what fixes
    // (structurally, not just patches) a fading popup "resurrecting"
    // itself if the cursor happens to pass back through it afterward:
    // it's no longer in the mask, so input passes straight through to
    // whatever's actually behind it.
    property var activePopupItems: []

    function registerPopup(item) {
        if (activePopupItems.indexOf(item) !== -1)
            return;
        activePopupItems = activePopupItems.concat([item]);
    }
    function unregisterPopup(item) {
        const idx = activePopupItems.indexOf(item);
        if (idx === -1)
            return;
        const copy = activePopupItems.slice();
        copy.splice(idx, 1);
        activePopupItems = copy;
    }
}
