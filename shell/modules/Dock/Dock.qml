pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import qs.core
import qs.services

BaseDrawer {
    id: dockRoot

    edge: Qt.BottomEdge
    openedRequest: ShellState.dockOpened
    toggleOnHover: true
    onCloseRequest: ShellState.dockOpened = false

    property bool contextMenuOpen: false

    minPanelHeight: 72 * Theme.scaleFor(screen)

    readonly property var _runningGroups: {
        const groups = {};
        for (const w of HyprlandData.windowList) {
            if (!w.mapped)
                continue;
            if (!groups[w.class])
                groups[w.class] = [];
            groups[w.class].push(w);
        }
        return groups;
    }

    readonly property var _runningByAppName: {
        const result = {};
        for (const cls in dockRoot._runningGroups) {
            const entry = DesktopEntryService.lookup(cls);
            const name = entry ? entry.name : cls;
            result[name] = {
                windows: dockRoot._runningGroups[cls],
                entry: entry
            };
        }
        return result;
    }

    function _findEntryByExactName(name) {
        const apps = DesktopEntries.applications?.values ?? [];
        return apps.find(a => a.name === name) ?? null;
    }

    readonly property var dockItems: {
        const items = [];
        const seen = new Set();

        for (const name of AppUsageService.favorites) {
            const running = dockRoot._runningByAppName[name];
            const entry = running ? running.entry : dockRoot._findEntryByExactName(name);
            items.push({
                name: name,
                entry: entry,
                iconPath: entry ? DesktopEntryService.resolveIconPath(entry.icon) : "",
                windows: running ? running.windows : []
            });
            seen.add(name);
        }
        for (const name in dockRoot._runningByAppName) {
            if (seen.has(name))
                continue;
            const running = dockRoot._runningByAppName[name];
            items.push({
                name: name,
                entry: running.entry,
                iconPath: running.entry ? DesktopEntryService.resolveIconPath(running.entry.icon) : "",
                windows: running.windows
            });
        }
        return items;
    }

    property var _cycleIndexByName: ({})

    function _focusWindow(win) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${win.address}" })`);
    }

    function _launch(item) {
        if (item.entry) {
            item.entry.execute();
            AppUsageService.recordLaunch(item.name);
            return;
        }
        Quickshell.execDetached([item.name]);
    }

    function activate(item) {
        if (item.windows.length === 0) {
            _launch(item);
            return;
        }
        if (item.windows.length === 1) {
            _focusWindow(item.windows[0]);
            return;
        }
        const cur = dockRoot._cycleIndexByName[item.name] ?? -1;
        const next = (cur + 1) % item.windows.length;
        const copy = Object.assign({}, dockRoot._cycleIndexByName);
        copy[item.name] = next;
        dockRoot._cycleIndexByName = copy;
        _focusWindow(item.windows[next]);
    }

    // ── Content ──────────────────────────────────────────────────────
    // Root is a plain Item, NOT the RowLayout itself — pinPopup lives
    // as a SIBLING of dockRow, structurally outside the RowLayout
    // entirely (not just excluded via some "ignore me" attached
    // property — QtQuick.Layouts has no Layout.ignoreLayout property
    // at all, that was a mistaken guess earlier — see chat). Being
    // outside the RowLayout by construction means it can NEVER be
    // counted toward dockRow's own width, regardless of pinPopup's own
    // dynamic `parent:` reassignment or visible state.
    contentComponent: Component {
        Item {
            id: dockContentRoot
            implicitWidth: dockRow.implicitWidth
            implicitHeight: dockRow.implicitHeight

            RowLayout {
                id: dockRow
                anchors.fill: parent
                spacing: 10 * Theme.scaleFor(dockRoot.screen)

                Repeater {
                    model: dockRoot.dockItems

                    delegate: ColumnLayout {
                        id: iconDelegate
                        required property var modelData
                        spacing: 3 * Theme.scaleFor(dockRoot.screen)

                        Rectangle {
                            id: iconRect
                            property alias hovered: hover.hovered

                            Layout.preferredWidth: 52 * Theme.scaleFor(dockRoot.screen)
                            Layout.preferredHeight: 52 * Theme.scaleFor(dockRoot.screen)
                            radius: Theme.radius
                            color: hover.hovered ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12) : "transparent"

                            Behavior on color {
                                AnimColor {
                                    type: Anim.FastEffects
                                }
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 34 * Theme.scaleFor(dockRoot.screen)
                                height: 34 * Theme.scaleFor(dockRoot.screen)
                                source: iconDelegate.modelData.iconPath !== "" ? iconDelegate.modelData.iconPath : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                visible: iconDelegate.modelData.iconPath !== ""
                            }
                            LucideIcon {
                                anchors.centerIn: parent
                                icon: "app-window"
                                size: 26 * Theme.scaleFor(dockRoot.screen)
                                color: Theme.foreground
                                opacity: 0.5
                                visible: iconDelegate.modelData.iconPath === ""
                            }

                            HoverHandler {
                                id: hover
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onTapped: {
                                    ShellState.closeDock();
                                    dockRoot.activate(iconDelegate.modelData);
                                }
                            }
                            TapHandler {
                                acceptedButtons: Qt.RightButton
                                onTapped: pinPopup.openFor(iconDelegate.modelData, iconRect)
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 5 * Theme.scaleFor(dockRoot.screen)
                            height: 5 * Theme.scaleFor(dockRoot.screen)
                            radius: width / 2
                            color: Theme.selected
                            visible: iconDelegate.modelData.windows.length > 0
                        }
                    }
                }
            }

            // ── Pin/unpin + window-picker popup ──────────────────────
            // Sibling of dockRow, not a child of it — see the note on
            // dockContentRoot above for why that matters.
            Item {
                id: pinPopup
                property var targetItem: null
                property Item anchorItem: null

                readonly property real _rowH: 34 * Theme.scaleFor(dockRoot.screen)
                readonly property real _sepH: 9 * Theme.scaleFor(dockRoot.screen)

                readonly property var _rows: {
                    if (!targetItem)
                        return [];
                    const rows = [
                        {
                            type: "pin"
                        }
                    ];
                    if (targetItem.windows.length > 1) {
                        rows.push({
                            type: "separator"
                        });
                        for (let i = 0; i < targetItem.windows.length; i++)
                            rows.push({
                                type: "window",
                                index: i
                            });
                    }
                    return rows;
                }

                readonly property bool _open: targetItem !== null
                readonly property bool _staysOpenViaHover: popupHover.hovered || (anchorItem ? anchorItem.hovered : false)

                parent: anchorItem ? (anchorItem.QsWindow.window?.contentItem ?? dockContentRoot) : dockContentRoot
                z: 200

                readonly property point _anchorPos: anchorItem ? anchorItem.mapToItem(pinPopup.parent, 0, 0) : Qt.point(0, 0)
                x: _anchorPos.x
                y: _anchorPos.y - height - (6 * Theme.scaleFor(dockRoot.screen))

                width: 190 * Theme.scaleFor(dockRoot.screen)
                height: {
                    let h = 0;
                    for (const r of _rows)
                        h += (r.type === "separator" ? _sepH : _rowH);
                    return h;
                }

                opacity: _open ? 1 : 0
                scale: _open ? 1 : 0.92
                visible: opacity > 0.01
                transformOrigin: Item.Bottom

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
                Behavior on scale {
                    Anim {
                        type: Anim.FastEffects
                    }
                }

                onVisibleChanged: {
                    dockRoot.contextMenuOpen = visible;
                    if (visible)
                        ShellState.registerPopup(pinPopup);
                    else
                        ShellState.unregisterPopup(pinPopup);
                }
                Component.onDestruction: ShellState.unregisterPopup(pinPopup)

                HoverHandler {
                    id: popupHover
                }

                Timer {
                    id: popupAutoCloseTimer
                    interval: 200
                    running: pinPopup._open && !pinPopup._staysOpenViaHover
                    onTriggered: pinPopup.close()
                }

                function openFor(item, anchor) {
                    if (pinPopup._open && pinPopup.anchorItem === anchor) {
                        pinPopup.close();
                        return;
                    }
                    pinPopup.targetItem = item;
                    pinPopup.anchorItem = anchor;
                }
                function close() {
                    pinPopup.targetItem = null;
                    pinPopup.anchorItem = null;
                }

                Rectangle {
                    id: popupBg
                    anchors.fill: parent
                    radius: Theme.radius
                    color: Theme.backgroundAlt
                    border.width: 1
                    border.color: Theme.borderColor
                }

                Item {
                    id: maskedRows
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: popupMaskShape
                    }

                    Column {
                        anchors.fill: parent

                        Repeater {
                            model: pinPopup._rows

                            delegate: Item {
                                id: rowRoot
                                required property var modelData
                                required property int index
                                width: pinPopup.width
                                height: rowRoot.modelData.type === "separator" ? pinPopup._sepH : pinPopup._rowH

                                Rectangle {
                                    visible: rowRoot.modelData.type === "separator"
                                    anchors.centerIn: parent
                                    width: parent.width - 16 * Theme.scaleFor(dockRoot.screen)
                                    height: 1
                                    color: Theme.borderColor
                                    opacity: 0.4
                                }

                                Rectangle {
                                    visible: rowRoot.modelData.type !== "separator"
                                    anchors.fill: parent
                                    color: rowHover.hovered ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.10) : "transparent"

                                    Behavior on color {
                                        AnimColor {
                                            type: Anim.FastEffects
                                        }
                                    }

                                    Text {
                                        anchors.fill: parent
                                        anchors.margins: 10 * Theme.scaleFor(dockRoot.screen)
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                        color: Theme.foreground
                                        font.family: Theme.fontName
                                        font.pixelSize: 13 * Theme.scaleFor(dockRoot.screen)
                                        text: {
                                            if (!pinPopup.targetItem)
                                                return "";
                                            if (rowRoot.modelData.type === "pin")
                                                return AppUsageService.isFavorite(pinPopup.targetItem.name) ? "Unpin from Dock" : "Pin to Dock";
                                            if (rowRoot.modelData.type === "window")
                                                return pinPopup.targetItem.windows[rowRoot.modelData.index].title || pinPopup.targetItem.name;
                                            return "";
                                        }
                                    }
                                    HoverHandler {
                                        id: rowHover
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    TapHandler {
                                        onTapped: {
                                            if (!pinPopup.targetItem)
                                                return;
                                            if (rowRoot.modelData.type === "pin")
                                                AppUsageService.toggleFavorite(pinPopup.targetItem.name);
                                            else if (rowRoot.modelData.type === "window")
                                                dockRoot._focusWindow(pinPopup.targetItem.windows[rowRoot.modelData.index]);
                                            pinPopup.close();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    id: popupMaskShape
                    anchors.fill: parent
                    radius: Theme.radius
                    visible: false
                }
            }

            Connections {
                target: dockRoot
                function onOpenedChanged() {
                    if (!dockRoot.opened)
                        pinPopup.close();
                }
            }
        }
    }
}
