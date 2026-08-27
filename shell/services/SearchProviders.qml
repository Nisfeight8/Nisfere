pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    // Each entry:
    //   id: string, unique
    //   keyword: string — "" means "default provider" (no keyword needed).
    //            Word-based keywords now carry their own "@" prefix as
    //            part of the string (e.g. "@tools", not "tools") — this
    //            disambiguates an explicit scope request ("@git") from
    //            someone just typing a plain app name that happens to
    //            match a provider name (typing "git" to find GitKraken
    //            used to force you into Git-Repos mode instead of
    //            searching apps; now only "@git" does that).
    //            ">" (commands) deliberately keeps NO "@" — single-char,
    //            no-space prefixes are handled separately below and are
    //            exclusive-only by nature (you don't want fuzzy-matched
    //            apps mixed into ">restart" style command entry).
    //   label, icon: shown in the dropdown picker + rotating placeholder
    //   pushOnActivate: bool — true = selecting a result pushes a panel
    //                    (stack), false = selecting a result executes
    //                    the action immediately and closes the launcher
    //   component: optional Component — full custom UI, bypasses the
    //              generic result-row rendering entirely (only "apps"
    //              needs this today, for its SideMenu+categories)
    //   search(query): function(string) -> array of
    //              { id, title, subtitle, icon, action }
    //
    // NOTE: `component` for "apps" is set from CentralLauncher.qml at
    // startup (root.providers[0].component = appLauncherComponent),
    // not here — importing the AppLauncher component from inside a
    // services/ singleton would be a backwards dependency direction.
    property var providers: [
        {
            id: "apps",
            keyword: "",
            label: "Apps",
            icon: "layout-grid",
            pushOnActivate: false,
            component: null,
            // Reuses DesktopEntryService.toResultRow — the same
            // mapping AppLauncherPanel's browse mode uses, so there's
            // one canonical "what does an app look like as a result
            // row" instead of two copies drifting apart. Capped at 50
            // — this feeds the unified flat search (searchAll below),
            // which can otherwise render hundreds of rows for a single
            // common letter.
            search: function (query) {
                const q = query.toLowerCase();
                return DesktopEntries.applications.values.filter(a => a.name.toLowerCase().includes(q)).slice(0, 50).map(a => DesktopEntryService.toResultRow(a));
            }
        },
        {
            id: "docker",
            keyword: "@docker",
            label: "Docker Manager",
            icon: "container",
            pushOnActivate: false,
            // Full standalone tool, not something you filter with
            // search text — SearchComponent hides the search bar while
            // one of these is the active provider (see its
            // `hideSearchBar`). Discoverability comes for free from
            // the "@" provider-picker (typing "@" lists every
            // provider, keyword included), so there's no "tools" menu
            // needed as a separate hop.
            standalone: true,
            component: null // set from CentralLauncher.qml, same as apps/wallpapers/colors
        },
        {
            id: "sysmon",
            keyword: "@sysmon",
            label: "System Monitor",
            icon: "activity",
            pushOnActivate: false,
            standalone: true,
            component: null
        },
        {
            id: "settings",
            keyword: "@settings",
            label: "Settings",
            icon: "settings",
            pushOnActivate: false,
            standalone: true,
            component: null
        },
        {
            id: "screenshot",
            keyword: "@screenshot",
            label: "Screenshot",
            icon: "camera",
            pushOnActivate: false,
            standalone: true,
            component: null
        },
        {
            id: "record",
            keyword: "@record",
            label: "Screen Recording",
            icon: "circle-dot",
            pushOnActivate: false,
            standalone: true,
            component: null
        },
        {
            id: "ssh",
            keyword: "@ssh",
            label: "SSH Servers",
            icon: "key",
            pushOnActivate: false // connects + closes launcher immediately
            ,
            search: function (query) {
                const q = query.toLowerCase();
                let hosts = SshHostsService.hosts;
                if (q !== "") {
                    hosts = hosts.filter(h => h.alias.toLowerCase().includes(q) || h.hostName.toLowerCase().includes(q) || h.user.toLowerCase().includes(q));
                }

                // Recent/most-used first, alphabetical otherwise — same
                // "decorate, sort, undecorate" approach as file
                // search's ranking (score computed once per item, not
                // recomputed inside the sort comparator).
                const decorated = hosts.map(h => {
                    const recentIdx = SshUsageService.recentAliases.indexOf(h.alias);
                    // Lower recentIdx = more recently used = higher
                    // priority; never-used (-1) sorts after anything
                    // that's ever been connected to.
                    const recencyScore = recentIdx === -1 ? -1 : (1000 - recentIdx);
                    return {
                        host: h,
                        recencyScore: recencyScore,
                        usageCount: SshUsageService.usageCount(h.alias)
                    };
                });
                decorated.sort((a, b) => {
                    if (a.recencyScore !== b.recencyScore)
                        return b.recencyScore - a.recencyScore;
                    if (a.usageCount !== b.usageCount)
                        return b.usageCount - a.usageCount;
                    return a.host.alias.localeCompare(b.host.alias);
                });

                return decorated.map(d => {
                    const h = d.host;
                    const displayHost = h.hostName !== "" ? h.hostName : h.alias;
                    // When the config doesn't specify a User, ssh
                    // falls back to your current OS username by
                    // default — showing NOTHING here was
                    // ambiguous about what would actually happen
                    // (e.g. a VPS you normally log into as "root"
                    // but ssh would actually attempt your local
                    // username, silently, unless you'd set User
                    // explicitly). Showing the real effective
                    // value either way removes that ambiguity.
                    const effectiveUser = h.user !== "" ? h.user : Quickshell.env("USER");
                    let subtitle = (effectiveUser ? effectiveUser + "@" : "") + displayHost;
                    if (h.port !== "" && h.port !== "22")
                        subtitle += ":" + h.port;

                    return {
                        id: "ssh-" + h.alias,
                        title: h.alias,
                        subtitle: subtitle,
                        icon: "server",
                        action: () => {
                            SshUsageService.recordConnect(h.alias);
                            root.runInTerminal("ssh " + h.alias);
                        }
                    };
                });
            }
        },
        {
            id: "git",
            keyword: "@git",
            label: "Git Repos",
            icon: "git-branch",
            // Was `true` ("pushes a repo-browser panel") — stale from
            // before the git manager became a standalone Dashboard
            // component (like Docker/Settings) instead of a pushed
            // search panel. `false` here means GenericResultsList
            // closes the search UI before running a row's action,
            // which for git means immediately opening the standalone
            // manager (see action below) — see ShellState's
            // openDashboardComponent for why that transition needed
            // its own small fix (a stale deferred close animation
            // could otherwise snap it back to "tabs" ~250ms later).
            pushOnActivate: false,
            search: function (query) {
                const q = query.toLowerCase();
                let repos = GitReposService.repos;
                if (q !== "")
                    repos = repos.filter(r => r.name.toLowerCase().includes(q) || r.path.toLowerCase().includes(q));

                // Recent/most-used first, alphabetical otherwise —
                // same "decorate, sort, undecorate" approach as the
                // ssh provider above.
                const decorated = repos.map(r => {
                    const recentIdx = GitUsageService.recentPaths.indexOf(r.path);
                    const recencyScore = recentIdx === -1 ? -1 : (1000 - recentIdx);
                    return {
                        repo: r,
                        recencyScore: recencyScore,
                        usageCount: GitUsageService.usageCount(r.path)
                    };
                });
                decorated.sort((a, b) => {
                    if (a.recencyScore !== b.recencyScore)
                        return b.recencyScore - a.recencyScore;
                    if (a.usageCount !== b.usageCount)
                        return b.usageCount - a.usageCount;
                    return a.repo.name.localeCompare(b.repo.name);
                });

                return decorated.map(d => {
                    const r = d.repo;
                    return {
                        id: "git-" + r.path,
                        title: r.name,
                        subtitle: r.path,
                        icon: "git-branch",
                        actions: [
                            {
                                icon: "terminal",
                                // action buttons (unlike the main
                                // row action below) don't go
                                // through GenericResultsList's
                                // automatic closeDashboard()-then-
                                // act flow — that's only applied to
                                // the row's own primary action, so
                                // each trigger needs to close
                                // explicitly or the dashboard just
                                // sits there open.
                                trigger: () => {
                                    root.runInTerminal("cd " + root._shellQuote(r.path));
                                    ShellState.closeDashboard();
                                }
                            },
                            {
                                icon: "folder-open",
                                // Same gio-open-with-xdg-open-fallback
                                // pattern used elsewhere.
                                trigger: () => {
                                    const quoted = root._shellQuote(r.path);
                                    Quickshell.execDetached(["sh", "-c", "gio open " + quoted + " 2>/dev/null || xdg-open " + quoted]);
                                    ShellState.closeDashboard();
                                }
                            }
                        ],
                        // Main action: open our own git manager for
                        // this specific repo — not a generic
                        // "browse" action, this repo's path becomes
                        // ShellState.gitManagerRepoPath.
                        action: () => {
                            GitUsageService.recordOpen(r.path);
                            ShellState.openGitManager(ShellState.activeScreenName, r.path);
                        }
                    };
                });
            }
        },
        {
            id: "containers",
            keyword: "@containers",
            label: "Docker Containers",
            icon: "box",
            pushOnActivate: false,
            // Fires once when you enter this scope (not on every
            // keystroke) — same hook clipboard's provider uses.
            // DockerService's own refresh timer only runs while the
            // full DockerManager GUI is open, so without this,
            // arriving here without ever having opened that GUI in
            // this session would show a stale/empty list.
            onScopeEnter: () => DockerService.requestDockerStats(),
            search: function (query) {
                const q = query.toLowerCase();

                // Two different kinds of row, merged into one ranked
                // list: compose PROJECTS (act on the whole stack) and
                // individual CONTAINERS (act on just one) — including
                // containers that belong to a compose project, not
                // just standalone ones. "Restart the whole dev stack"
                // and "just restart the backend" are both one click,
                // at whichever granularity you actually want right
                // now (see chat for the reasoning).
                const items = [];

                for (const projectName in DockerService.composeProjects) {
                    const project = DockerService.composeProjects[projectName];
                    if (q === "" || projectName.toLowerCase().includes(q))
                        items.push({
                            kind: "compose",
                            key: "compose:" + projectName,
                            name: projectName,
                            project: project
                        });
                    for (const c of project.containers) {
                        if (q === "" || c.name.toLowerCase().includes(q) || projectName.toLowerCase().includes(q))
                            items.push({
                                kind: "container",
                                key: "container:" + c.name,
                                name: c.name,
                                container: c,
                                projectName: projectName
                            });
                    }
                }
                for (const c of DockerService.standaloneContainers) {
                    if (q === "" || c.name.toLowerCase().includes(q))
                        items.push({
                            kind: "container",
                            key: "container:" + c.name,
                            name: c.name,
                            container: c,
                            projectName: ""
                        });
                }

                // Same "decorate, sort, undecorate" ranking as ssh/git
                // above — recency/usage first, alphabetical otherwise.
                const decorated = items.map(item => {
                    const recentIdx = DockerUsageService.recentKeys.indexOf(item.key);
                    const recencyScore = recentIdx === -1 ? -1 : (1000 - recentIdx);
                    return {
                        item: item,
                        recencyScore: recencyScore,
                        usageCount: DockerUsageService.usageCount(item.key)
                    };
                });
                decorated.sort((a, b) => {
                    if (a.recencyScore !== b.recencyScore)
                        return b.recencyScore - a.recencyScore;
                    if (a.usageCount !== b.usageCount)
                        return b.usageCount - a.usageCount;
                    return a.item.name.localeCompare(b.item.name);
                });

                return decorated.map(d => {
                    const item = d.item;

                    if (item.kind === "compose") {
                        const count = item.project.containers.length;
                        return {
                            id: "docker-" + item.key,
                            title: item.name,
                            subtitle: count + (count === 1 ? " container" : " containers"),
                            icon: "layers",
                            actions: [
                                {
                                    icon: "play",
                                    trigger: () => {
                                        DockerUsageService.recordUse(item.key);
                                        DockerService.composeAction("up", item.project);
                                        ShellState.closeDashboard();
                                    }
                                },
                                {
                                    icon: "refresh-cw",
                                    trigger: () => {
                                        DockerUsageService.recordUse(item.key);
                                        DockerService.composeAction("restart", item.project);
                                        ShellState.closeDashboard();
                                    }
                                }
                            ],
                            action: () => ShellState.openDocker(ShellState.activeScreenName)
                        };
                    }

                    // kind === "container"
                    const c = item.container;
                    const isRunning = c.status === "running";
                    const containerActions = isRunning ? [
                        {
                            icon: "square",
                            trigger: () => {
                                DockerUsageService.recordUse(item.key);
                                DockerService.containerAction("stop", c.id);
                                ShellState.closeDashboard();
                            }
                        },
                        {
                            icon: "refresh-cw",
                            trigger: () => {
                                DockerUsageService.recordUse(item.key);
                                DockerService.containerAction("restart", c.id);
                                ShellState.closeDashboard();
                            }
                        }
                    ] : [
                        {
                            icon: "play",
                            trigger: () => {
                                DockerUsageService.recordUse(item.key);
                                DockerService.containerAction("start", c.id);
                                ShellState.closeDashboard();
                            }
                        }
                    ];

                    return {
                        id: "docker-" + item.key,
                        title: item.name,
                        subtitle: c.status + (item.projectName !== "" ? " · part of " + item.projectName : " · standalone"),
                        icon: "box",
                        actions: containerActions,
                        // Opens straight to THIS container's details
                        // view — DockerManager always starts fresh
                        // on the Containers tab (currentTab: 0), and
                        // DockerService.requestAndNavigate is the
                        // same call ContainerRow.qml itself uses on
                        // click, so ContainersWidget's AnimLoader
                        // (driven by DockerService.isViewingDetails)
                        // shows the details view immediately — no
                        // new ShellState property needed, unlike
                        // git's gitManagerRepoPath (Docker already
                        // had this state living in DockerService).
                        action: () => {
                            ShellState.openDocker(ShellState.activeScreenName);
                            DockerService.requestAndNavigate(c.id);
                        }
                    };
                });
            }
        },
        {
            id: "clipboard",
            keyword: "@clip",
            label: "Clipboard History",
            icon: "clipboard-list",
            pushOnActivate: false,
            component: null // set from CentralLauncher.qml, same as apps/wallpapers/colors
        },
        {
            id: "files",
            keyword: "@files",
            label: "File Search",
            icon: "file-search",
            pushOnActivate: false,
            component: null // set from CentralLauncher.qml, same as apps/wallpapers/colors
        },
        {
            id: "colorpicker",
            keyword: "@pick",
            label: "Color Picker",
            icon: "pipette",
            pushOnActivate: false,
            // No list to show at all — this used to return a single
            // fixed search() result you still had to click/Enter on,
            // which was a pointless extra step (nothing to actually
            // pick). `immediate: true` + this top-level `action` make
            // SearchComponent's onParsedChanged (same place that
            // redirects "standalone" providers like docker/settings)
            // run this the INSTANT the "@pick" keyword locks in —
            // typing it, or selecting it from the "@" picker, both go
            // through dashboardSearchText changing, so both trigger
            // it the same way, automatically.
            immediate: true,
            action: function () {
                root.runColorPicker();
            }
        },
        {
            id: "wallpapers",
            keyword: "@wp",
            label: "Wallpapers",
            icon: "image",
            pushOnActivate: false,
            component: null // set from CentralLauncher.qml, same as apps/colors
        },
        {
            id: "colors",
            keyword: "@color",
            label: "Color Themes",
            icon: "pipette",
            pushOnActivate: false,
            component: null // set from CentralLauncher.qml, same reason as "apps"
        },
        {
            id: "websearch",
            keyword: "@web",
            label: "Web Search",
            icon: "globe",
            pushOnActivate: false,
            // Same "one row = exactly what you typed" shape as
            // "commands" above — nothing to filter, the query itself
            // IS the result.
            search: function (query) {
                if (query.trim() === "")
                    return [];
                return [
                    {
                        id: "web-search-run",
                        title: query,
                        subtitle: "Search the web",
                        icon: "globe",
                        action: () => root.runWebSearch(query)
                    }
                ];
            }
        },
        {
            id: "commands",
            keyword: ">",
            label: "Run Command",
            icon: "terminal",
            pushOnActivate: false // executes immediately
            ,
            // Single result mirroring exactly what you typed after
            // ">" — this isn't a search over a fixed list, so there's
            // nothing to filter; the "match" IS the command itself.
            // Empty query = nothing to run yet, so no row at all
            // (matches every other provider's "type something first"
            // convention rather than showing a dead/empty entry).
            //
            // AUTOCOMPLETE HOOK (not implemented yet — see chat): once
            // the daemon's compgen-based completion endpoint exists,
            // this is the place to request suggestions (e.g.
            // SocketService.sendCommand("shell", "complete", { input:
            // query }), debounced ~120ms) and surface them as
            // additional rows above/alongside this one. For now it's
            // just the single "run exactly this" row.
            search: function (query) {
                if (query.trim() === "")
                    return [];
                return [
                    {
                        id: "run-command",
                        title: query,
                        subtitle: "Run in terminal",
                        icon: "terminal",
                        action: () => root.runInTerminal(query)
                    }
                ];
            }
        }
    ]

    // Terminal emulator to launch commands in — reads $TERMINAL first
    // (respects whatever you've already set in your shell/Hyprland
    // config), falls back to alacritty if that's unset. Only used by
    // the FALLBACK path in runInTerminal() now (see below) — the
    // primary path routes through the TerminalDrawer's own already-
    // running shell session instead of spawning a separate process.
    function _terminalEmulator() {
        const fromEnv = Quickshell.env("TERMINAL");
        return (fromEnv && fromEnv !== "") ? fromEnv : "alacritty";
    }

    // Same reasoning as _terminalEmulator() above — only used by the
    // fallback spawn path now.
    function _userShell() {
        const fromEnv = Quickshell.env("SHELL");
        return (fromEnv && fromEnv !== "") ? fromEnv : "/bin/sh";
    }

    // Safe single-quote wrapping for embedding arbitrary text inside a
    // shell -c string — escapes any embedded single quotes. Still used
    // by callers building a literal command string (e.g. git's "open
    // terminal here" action does `"cd " + _shellQuote(path)`) — that
    // string still goes through runInTerminal() below either way,
    // whether it ends up typed into the drawer's live shell or (in the
    // fallback case) passed to `sh -c`.
    function _shellQuote(str) {
        return "'" + str.replace(/'/g, "'\\''") + "'";
    }

    // Runs cmd in a terminal — used for arbitrary typed commands (the
    // ">" provider), picking an already-configured SSH host, and
    // opening a git repo's terminal.
    //
    // Was: always Quickshell.execDetached(...) a brand-new alacritty
    // process. Now: routes through the TerminalDrawer registered for
    // the active screen (see ShellState.terminalDrawersByScreen) —
    // opens the drawer if it's closed, and sends the command text
    // directly into whatever tab TerminalDrawer's own
    // getOrCreateFreshTab()/runCommand() logic picks (a tab that's
    // never had a programmatic command sent to it before, or a new
    // one if every existing tab has already run something — see
    // TerminalDrawer.qml). This is a straight typed-command send, not
    // a `sh -c cmd; exec shell` wrapper trick — it's your actual login
    // shell already running in that tab, so no quoting/exec games are
    // needed for the primary path at all.
    //
    // Falls back to spawning a real terminal ONLY if no drawer is
    // registered for the target screen at all — shouldn't normally
    // happen given TerminalDrawer's preload:true (it registers itself
    // at shell startup, well before any search action could run), but
    // this is a safety net rather than silently doing nothing if that
    // assumption is ever wrong.
    function runInTerminal(cmd) {
        const screenName = ShellState.activeScreenName || ShellState.focusedScreenName;
        const api = ShellState.terminalDrawersByScreen[screenName];
        if (api) {
            ShellState.openTerminalDrawer(screenName);
            api.runCommand(cmd);
            return;
        }
        const shell = root._userShell();
        Quickshell.execDetached([root._terminalEmulator(), "-e", shell, "-c", cmd + "; exec " + shell]);
    }

    // Default search engine — one line to change if you'd rather use
    // DuckDuckGo/Bing/etc (e.g. "https://duckduckgo.com/?q=%s"). A
    // Settings toggle for this is a natural future addition, same as
    // the terminal emulator override mentioned earlier — not wired up
    // yet, this is the whole decision for now.
    readonly property string _searchEngineUrlTemplate: "https://www.google.com/search?q=%s"

    // xdg-open respects whatever you've set as your default browser
    // (xdg-settings/mimeapps.list) — no need to hardcode a specific
    // browser binary. Opening a URL while that browser is already
    // running opens a new TAB in the existing window automatically;
    // that's the browser's own single-instance IPC behavior (every
    // major browser does this), not something we need to detect or
    // implement ourselves. Same execDetached() fix as
    // runInTerminal above — same reused-Process bug applied here
    // too (had to close the browser window before a second search
    // would open anything).
    function runWebSearch(query) {
        const url = root._searchEngineUrlTemplate.replace("%s", encodeURIComponent(query));
        Quickshell.execDetached(["xdg-open", url]);
    }

    // Delay before actually running the color picker — closeDashboard()
    // (called by GenericResultsList's activation logic before
    // r.action() runs) starts the drawer's close animation, but
    // hyprpicker needs the screen actually clear of any overlay first.
    // Same 200ms the old bottom-drawer's QuickActions used.
    Timer {
        id: _pickerDelayTimer
        interval: ShellState.drawerDelayInterval
        onTriggered: ColorPickerService.run()
    }

    // Public entry point for anything that wants to trigger the color
    // picker directly without going through search at all (e.g. the
    // Dashboard footer's 1-click shortcut) — same delay mechanism the
    // "colorpicker" provider's own search() result uses above, just
    // exposed so callers don't need to fake a search interaction to
    // reach it.
    function runColorPicker() {
        _pickerDelayTimer.restart();
    }

    // Providers with a non-empty keyword — used both for parsing and
    // for populating the rotating placeholder / dropdown list.
    readonly property var keywordProviders: providers.filter(p => p.keyword !== "")

    // The providers that participate in the unified, no-prefix flat
    // search — i.e. typing plain text with no "@keyword" searches all
    // of these together, apps included, each result tagged with its
    // providerId/providerIcon below (GenericResultsList uses this tag
    // to know which provider "owns" a given row when the results are
    // merged from more than one source). Deliberately excludes:
    // "wallpapers"/"colors" (own custom panel UI, not generic rows),
    // "commands" (exclusive-only by design — see the note on ">" above).
    readonly property var flatSearchProviderIds: ["apps", "ssh", "git"]

    // Merged results from every flatSearchProviderIds entry, each
    // tagged with providerId/providerIcon so a generic result row can
    // show a small "came from Tools/SSH/Git" badge.
    function searchAll(query) {
        let out = [];
        for (const id of root.flatSearchProviderIds) {
            const p = root.findById(id);
            if (!p || !p.search)
                continue;
            const tagged = p.search(query).map(r => Object.assign({}, r, {
                    providerId: id,
                    providerIcon: p.icon
                }));
            out = out.concat(tagged);
        }
        return out;
    }

    function findById(id) {
        return providers.find(p => p.id === id) ?? null;
    }

    // "@ssh myserver" -> { providerId: "ssh", rest: "myserver" }
    // "firefox"       -> { providerId: "apps", rest: "firefox" }
    // ">htop"         -> { providerId: "commands", rest: "htop" } (no-space keyword)
    function parseQuery(text) {
        // No-space keywords (like ">") first — these match as a pure
        // prefix, not a whole first word.
        for (const p of root.keywordProviders) {
            if (p.keyword.length > 0 && !/\s/.test(p.keyword) && text.startsWith(p.keyword) && p.keyword.length === 1) {
                return {
                    providerId: p.id,
                    rest: text.substring(p.keyword.length)
                };
            }
        }

        const spaceIdx = text.indexOf(" ");
        const firstWord = spaceIdx === -1 ? text : text.substring(0, spaceIdx);
        const provider = root.keywordProviders.find(p => p.keyword === firstWord);

        if (provider) {
            return {
                providerId: provider.id,
                rest: spaceIdx === -1 ? "" : text.substring(spaceIdx + 1)
            };
        }

        // "@..." that hasn't (yet) matched a full keyword above — live
        // provider-picker suggestions, filtered by whatever's typed
        // after the "@" so far. Covers "@", "@t", "@too", and even a
        // mistyped "@xyz" that never resolves to a real provider
        // (rather than silently falling through to a plain apps
        // search, which would be confusing right after typing "@").
        if (firstWord.startsWith("@")) {
            return {
                providerId: "providerSuggest",
                rest: firstWord.substring(1)
            };
        }

        return {
            providerId: "apps",
            rest: text
        };
    }
}
