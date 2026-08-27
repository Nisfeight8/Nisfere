pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QMLTermWidget
import qs.core
import qs.services

BaseDrawer {
    id: terminalRoot
    z: 10
    preload: true
    edge: Qt.BottomEdge
    openedRequest: ShellState.terminalOpened
    minPanelHeight: 550 * Theme.scaleFor(screen)
    minPanelWidth: screen.width / 1.1 * Theme.scaleFor(screen)
    // Open/close is keyboard-driven now (see IpcHandlers.qml's
    // "terminal" target) — false here so the drawer doesn't ALSO
    // auto-close itself whenever the mouse happens to leave it, which
    // would fight with that (BaseDrawer's own hover-based auto-close
    // logic is independent of triggerHovered/bezel wiring — it reacts
    // to hovering the drawer's own content too).
    toggleOnHover: false
    onCloseRequest: ShellState.terminalOpened = false

    contentComponent: Component {
        Item {
            id: contentRoot

            // ── Tab state ────────────────────────────────────────────
            // Each entry: { key, item (the live QMLTermWidget
            // instance), label, hasRunCommand }. Deliberately NOT
            // rendered via a Repeater bound to this array directly —
            // replacing the array reference (which `tabs = tabs.
            // concat([...])` / `tabs = newTabs` both do) would destroy
            // and recreate every delegate's item, killing every OTHER
            // tab's live shell session just from opening or closing
            // ONE tab. Instead: the tab BAR below uses an integer
            // count as its model (see chat — same reactive-count
            // pattern sidesteps that whole class of bug), and each
            // QMLTermWidget instance is created/destroyed manually via
            // createObject()/destroy(), living independently of
            // whatever the tab bar's own delegates are doing.
            property var tabs: []
            property int activeTabIndex: -1
            readonly property var activeTab: (activeTabIndex >= 0 && activeTabIndex < tabs.length) ? tabs[activeTabIndex] : null

            Component {
                id: tabComponent
                QMLTermWidget {
                    id: terminal
                    font.family: "monospace"
                    font.pointSize: 12
                    colorScheme: ThemeState.terminalColorScheme !== "" ? ThemeState.terminalColorScheme : "cool-retro-term"

                    session: QMLTermSession {
                        id: session
                        initialWorkingDirectory: "$HOME"
                    }
                    Component.onCompleted: {
                        session.startShellProgram();
                    }

                    QMLTermScrollbar {
                        terminal: terminal
                        width: 20
                        Rectangle {
                            opacity: 0.4
                            anchors.margins: 5
                            radius: width * 0.5
                            anchors.fill: parent
                        }
                    }
                }
            }

            function createTab() {
                const item = tabComponent.createObject(tabHost);
                item.anchors.fill = tabHost;
                item.visible = false;
                const tab = {
                    key: Date.now() + "-" + Math.random(),
                    item: item,
                    hasRunCommand: false
                };
                contentRoot.tabs = contentRoot.tabs.concat([tab]);
                switchToTab(contentRoot.tabs.length - 1);
                return tab;
            }

            function closeTab(index) {
                if (index < 0 || index >= contentRoot.tabs.length)
                    return;
                const tab = contentRoot.tabs[index];
                tab.item.session.sendSignal(1);
                tab.item.destroy();

                const newTabs = contentRoot.tabs.slice();
                newTabs.splice(index, 1);
                contentRoot.tabs = newTabs;

                if (contentRoot.tabs.length === 0) {
                    contentRoot.activeTabIndex = -1;
                    ShellState.terminalOpened = false;
                    return;
                }
                switchToTab(Math.min(index, contentRoot.tabs.length - 1));
            }

            function switchToTab(index) {
                if (index < 0 || index >= contentRoot.tabs.length)
                    return;
                for (let i = 0; i < contentRoot.tabs.length; i++)
                    contentRoot.tabs[i].item.visible = (i === index);
                contentRoot.activeTabIndex = index;
                contentRoot.tabs[index].item.forceActiveFocus();
            }

            function nextTab() {
                if (contentRoot.tabs.length < 2)
                    return;
                switchToTab((contentRoot.activeTabIndex + 1) % contentRoot.tabs.length);
            }
            function previousTab() {
                if (contentRoot.tabs.length < 2)
                    return;
                switchToTab((contentRoot.activeTabIndex - 1 + contentRoot.tabs.length) % contentRoot.tabs.length);
            }

            function getOrCreateFreshTab() {
                const idx = contentRoot.tabs.findIndex(t => !t.hasRunCommand);
                if (idx !== -1) {
                    switchToTab(idx);
                    return contentRoot.tabs[idx];
                }
                return createTab();
            }
            function runCommand(cmd) {
                const tab = getOrCreateFreshTab();
                tab.item.session.sendText(cmd + "\n");
                tab.hasRunCommand = true;
            }

            Component.onCompleted: {
                createTab();
                if (terminalRoot.screenName !== "")
                    ShellState.registerTerminalDrawer(terminalRoot.screenName, {
                        runCommand: contentRoot.runCommand
                    });
            }
            Component.onDestruction: {
                if (terminalRoot.screenName !== "")
                    ShellState.unregisterTerminalDrawer(terminalRoot.screenName);
            }

            // enabled: terminalRoot.opened on every Action below —
            // Action.shortcut is a GLOBAL, window-wide key grab, quite
            // unlike Keys.onXPressed (which only fires when that
            // specific Item has focus). preload:true keeps this whole
            // contentComponent permanently loaded even while the
            // drawer is closed, so without this guard every one of
            // these shortcuts was intercepting its key combination
            // ALWAYS — not just while the terminal was actually open.
            // Escape was the most visible case: it was swallowing the
            // key globally, silently no-opping (ShellState.
            // terminalOpened was already false), which meant NO OTHER
            // component's own Keys.onEscapePressed (Dashboard,
            // Settings, ...) ever got a chance to see the event at
            // all while TerminalDrawer existed in the tree — a symptom
            // that looked like "Escape is broken everywhere" and only
            // went away when TerminalDrawer was removed entirely.
            Action {
                enabled: terminalRoot.opened
                onTriggered: contentRoot.activeTab?.item.copyClipboard()
                shortcut: "Ctrl+Shift+C"
            }
            Action {
                enabled: terminalRoot.opened
                onTriggered: contentRoot.activeTab?.item.pasteClipboard()
                shortcut: "Ctrl+Shift+V"
            }
            Action {
                enabled: terminalRoot.opened
                onTriggered: contentRoot.createTab()
                shortcut: "Ctrl+Shift+T"
            }
            Action {
                enabled: terminalRoot.opened
                // Shift deliberately included — plain Ctrl+W is
                // readline's own "delete word" binding inside the
                // shell itself; without Shift this would fight with
                // that instead of closing the tab.
                onTriggered: contentRoot.closeTab(contentRoot.activeTabIndex)
                shortcut: "Ctrl+Shift+W"
            }
            Action {
                enabled: terminalRoot.opened
                onTriggered: contentRoot.nextTab()
                shortcut: "Ctrl+Tab"
            }
            Action {
                enabled: terminalRoot.opened
                onTriggered: contentRoot.previousTab()
                shortcut: "Ctrl+Shift+Tab"
            }
            Action {
                enabled: terminalRoot.opened
                // Same convention as the rest of this shell (e.g.
                // Settings' Keys.onEscapePressed: ShellState.
                // closeDashboard()) — Escape closes the drawer.
                onTriggered: ShellState.closeTerminalDrawer()
                shortcut: "Ctrl+Escape"
            }

            // Re-grabs keyboard focus for the active tab whenever the
            // pointer enters the drawer anywhere — covers focus having
            // been lost to some other window/widget in the meantime
            // (e.g. clicking elsewhere then hovering back), without
            // needing an explicit click first.
            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        contentRoot.activeTab?.item.forceActiveFocus();
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ── Tab bar ──────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32 * Theme.scaleFor(terminalRoot.screen)
                    // Defensive cap — guarantees this row can never
                    // visually grow taller than intended regardless of
                    // any child's own implicit size, and clip:true
                    // below crops anything that still tries to.
                    Layout.maximumHeight: 32 * Theme.scaleFor(terminalRoot.screen)
                    clip: true
                    spacing: 4 * Theme.scaleFor(terminalRoot.screen)

                    Repeater {
                        // Integer count, not the tabs array itself —
                        // see the big comment on `tabs` above for why.
                        model: contentRoot.tabs.length

                        delegate: Rectangle {
                            id: tabChip
                            required property int index

                            Layout.preferredWidth: 140 * Theme.scaleFor(terminalRoot.screen)
                            Layout.fillHeight: true
                            radius: Theme.radius
                            color: index === contentRoot.activeTabIndex ? Theme.selected : Theme.backgroundAlt

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8 * Theme.scaleFor(terminalRoot.screen)
                                anchors.rightMargin: 4 * Theme.scaleFor(terminalRoot.screen)
                                spacing: 4 * Theme.scaleFor(terminalRoot.screen)

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    TapHandler {
                                        onTapped: contentRoot.switchToTab(index)
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        text: "Terminal " + (index + 1)
                                        color: index === contentRoot.activeTabIndex ? Theme.backgroundAlt : Theme.foreground
                                        elide: Text.ElideRight
                                        font.family: Theme.fontName
                                        font.pixelSize: 12 * Theme.scaleFor(terminalRoot.screen)
                                    }
                                }
                                IconButton {
                                    icon: "x"
                                    size: 20 * Theme.scaleFor(terminalRoot.screen)
                                    iconSize: 12 * Theme.scaleFor(terminalRoot.screen)
                                    normalColor: "transparent"
                                    hoverColor: index === contentRoot.activeTabIndex ? Theme.background : Theme.selected
                                    fixedIconColor: index === contentRoot.activeTabIndex ? Theme.background : Theme.selected
                                    onTapped: contentRoot.closeTab(index)
                                }
                            }
                        }
                    }

                    IconButton {
                        icon: "plus"
                        size: 28 * Theme.scaleFor(terminalRoot.screen)
                        iconSize: 14 * Theme.scaleFor(terminalRoot.screen)
                        tooltipText: "New Tab (Ctrl+Shift+T)"
                        onTapped: contentRoot.createTab()
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                // ── Active terminal host ─────────────────────────────
                // The actual QMLTermWidget instances are parented here
                // manually (see createTab()) — this Item just reserves
                // the layout space for whichever one is currently
                // visible.
                Item {
                    id: tabHost
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 10
                }
            }

            // Re-focuses the active tab every time the drawer is shown
            // — still needed since preload keeps this content alive
            // across close/reopen (Component.onCompleted only fires
            // once, at initial creation). Also recreates a tab if the
            // drawer was left with zero (e.g. you closed the last tab
            // last time, which also closes the drawer — see
            // closeTab()).
            Connections {
                target: terminalRoot
                function onOpenedChanged() {
                    if (!terminalRoot.opened)
                        return;
                    if (contentRoot.tabs.length === 0) {
                        contentRoot.createTab();
                        return;
                    }
                    contentRoot.activeTab?.item.forceActiveFocus();
                }
            }
        }
    }
}
