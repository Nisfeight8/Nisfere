pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.Bar
import qs.modules.Dashboard
import qs.modules.ControlCenter
import qs.modules.SystemDrawer
import qs.modules.TerminalDrawer
import qs.modules.Dock
import qs.modules.Osd
import qs.modules.NotificationPopup
import qs.modules.WorkspaceOverview
import qs.modules.WallpaperOverlay

import qs.core
import qs.services

// One instance of everything below per screen (Variants). Each
// instance gets its own visualWindow + ExclusionZones bound to that
// specific screen via `screen: modelData`.
Variants {
    id: screenVariants
    model: Quickshell.screens

    Scope {
        id: rootScope
        required property var modelData
        readonly property var screen: modelData

        property real bezelSize: Theme.screenBorderSize
        readonly property real topBarHeight: Theme.scaledBarHeight(screen)

        // ---------------------------------------------------------
        // 1. VISUAL WINDOW
        // ---------------------------------------------------------
        PanelWindow {
            id: visualWindow
            screen: rootScope.screen

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            readonly property bool _isActiveScreen: screen && ShellState.activeScreenName === screen.name

            readonly property bool isAnyUIOpen: _isActiveScreen && (ShellState.dashboardWantsOverlayLayer || ShellState.overviewOpen || ShellState.controlCenterWantsOverlayLayer)

            readonly property bool needsExclusiveFocus: _isActiveScreen && (ShellState.overviewOpen || ShellState.terminalOpened || ShellState.dashboardWantsExclusiveFocus)
            readonly property bool needsOnDemandFocus: _isActiveScreen && (ShellState.dashboardWantsOnDemandFocus || ShellState.controlCenterWantsOnDemandFocus)

            readonly property var _monitorData: screen ? HyprlandData.monitors.values.find(m => m.name === screen.name) : null

            readonly property bool hasFullscreen: screen ? HyprlandData.hasFullscreenOnScreen(screen.name) : false
            readonly property bool showingWallpaper: screen ? HyprlandData.isShowingWallpaper(screen.name) : false

            onHasFullscreenChanged: {
                if (!hasFullscreen || !_isActiveScreen)
                    return;
                if (ShellState.dashboardOpened)
                    ShellState.closeDashboard();
                if (ShellState.controlCenterOpened)
                    ShellState.closeControlCenter();
                if (ShellState.systemDrawerOpened)
                    ShellState.closeSystemDrawer();
                ShellState.activePopupItems = [];
            }

            function _yOverlaps(other) {
                if (!_monitorData || !other)
                    return false;
                const aTop = _monitorData.y, aBottom = _monitorData.y + _monitorData.height;
                const bTop = other.y, bBottom = other.y + other.height;
                return aTop < bBottom && bTop < aBottom;
            }
            function _xOverlaps(other) {
                if (!_monitorData || !other)
                    return false;
                const aLeft = _monitorData.x, aRight = _monitorData.x + _monitorData.width;
                const bLeft = other.x, bRight = other.x + other.width;
                return aLeft < bRight && bLeft < aRight;
            }
            readonly property bool hasMonitorToLeft: _monitorData ? HyprlandData.monitors.values.some(m => m.name !== _monitorData.name && Math.abs((m.x + m.width) - _monitorData.x) < 2 && _yOverlaps(m)) : false
            readonly property bool hasMonitorToRight: _monitorData ? HyprlandData.monitors.values.some(m => m.name !== _monitorData.name && Math.abs(m.x - (_monitorData.x + _monitorData.width)) < 2 && _yOverlaps(m)) : false
            readonly property bool hasMonitorAbove: _monitorData ? HyprlandData.monitors.values.some(m => m.name !== _monitorData.name && Math.abs((m.y + m.height) - _monitorData.y) < 2 && _xOverlaps(m)) : false
            readonly property bool hasMonitorBelow: _monitorData ? HyprlandData.monitors.values.some(m => m.name !== _monitorData.name && Math.abs(m.y - (_monitorData.y + _monitorData.height)) < 2 && _xOverlaps(m)) : false

            WlrLayershell.keyboardFocus: needsExclusiveFocus ? WlrKeyboardFocus.Exclusive : (needsOnDemandFocus ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
            WlrLayershell.layer: (isAnyUIOpen || osd.shown || notificationPopup.shown) ? WlrLayer.Overlay : WlrLayer.Top

            anchors {
                bottom: true
                left: true
                right: true
                top: true
            }

            Bar {
                id: bar
                visible: !visualWindow.hasFullscreen
            }

            OSD {
                id: osd
                z: 20
                hasFullscreen: visualWindow.hasFullscreen
            }
            NotificationPopup {
                id: notificationPopup
                z: 20
                hasFullscreen: visualWindow.hasFullscreen
            }

            AnimatedContentLoader {
                id: overviewLoader
                z: 50
                anchors.fill: parent
                shouldBeActive: ShellState.overviewOpen && visualWindow.screen && ShellState.activeScreenName === visualWindow.screen.name
                sourceComponent: Component {
                    WorkspaceOverview {
                        screen: visualWindow.screen
                    }
                }
            }

            // ── Drawers ──────────────────────────────────────────────
            // Explicit z above BorderBezels (which paints after these
            // in file order otherwise, and would sit ON TOP of them by
            // default sibling paint order — that's exactly why the
            // bottom accent line stayed visible OVER the open Terminal
            // drawer). z here makes the drawer's own panel actually
            // paint over that line when open, the same way it should
            // for every edge — not hiding the line via opacity, just
            // correctly stacking the drawer above it.
            Dashboard {
                id: dashboardDrawer
                z: 10
                screen: visualWindow.screen
                visible: !visualWindow.hasFullscreen
                triggerHovered: borderBezels.topHovered
            }
            ControlCenter {
                id: controlCenterDrawer
                z: 10
                screen: visualWindow.screen
                visible: !visualWindow.hasFullscreen
                triggerHovered: borderBezels.rightHovered
            }
            SystemDrawer {
                id: systemDrawer
                z: 10
                screen: visualWindow.screen
                visible: !visualWindow.hasFullscreen
                triggerHovered: borderBezels.leftHovered
            }
            TerminalDrawer {
                id: terminalDrawer
                z: 10
                screen: visualWindow.screen
                visible: !visualWindow.hasFullscreen
            }
            Dock {
                id: dock
                z: 10
                screen: visualWindow.screen
                visible: !visualWindow.hasFullscreen
                triggerHovered: borderBezels.bottomHovered || dock.contextMenuOpen
            }
            Loader {
                id: wallpaperOverlayLoader
                anchors.fill: parent
                active: visualWindow.showingWallpaper
                sourceComponent: Component {
                    WallpaperOverlay {}
                }
            }
            // ── Border bezels + hover detection ──
            BorderBezels {
                id: borderBezels
                visible: !visualWindow.hasFullscreen
                bezelSize: rootScope.bezelSize
                topBarHeight: rootScope.topBarHeight
            }

            // BorderBezels' accent lines are now correctly covered by
            // each drawer's own panel via z-ordering (see the z: 10 on
            // each drawer above) whenever that drawer is open — no
            // extra logic needed here.

            Connections {
                target: borderBezels
                function onTopHoveredChanged() {
                    if (!visualWindow.screen)
                        return;
                    if (borderBezels.topHovered && !dashboardDrawer.toggleOnHover)
                        return; // dashboard uses toggleOnHover:false, ignore hover-open here
                    if (borderBezels.topHovered && !visualWindow.hasMonitorAbove)
                        ShellState.openDashboardTabs(visualWindow.screen.name);
                }
                // Terminal is keyboard-triggered only now (see
                // IpcHandlers.qml's "terminal" IPC target +
                // keybinds.lua's SUPER+grave) — freed the bottom edge
                // for the Dock's own hover trigger below.
                //
                // Gated on !terminalDrawer.opened so hovering the
                // bottom edge while the terminal is already open
                // (covering that same screen area) doesn't ALSO pop
                // the Dock up underneath/over it — the two share the
                // same edge but are mutually exclusive triggers.
                function onBottomHoveredChanged() {
                    if (!visualWindow.screen)
                        return;
                    if (borderBezels.bottomHovered && dock.toggleOnHover && !terminalDrawer.opened && !visualWindow.hasMonitorBelow)
                        ShellState.openDock(visualWindow.screen.name);
                }
                function onLeftHoveredChanged() {
                    if (!visualWindow.screen)
                        return;
                    if (borderBezels.leftHovered && systemDrawer.toggleOnHover && !visualWindow.hasMonitorToLeft)
                        ShellState.openSystemDrawer(visualWindow.screen.name);
                }
                function onRightHoveredChanged() {
                    if (!visualWindow.screen)
                        return;
                    if (borderBezels.rightHovered && controlCenterDrawer.toggleOnHover && !visualWindow.hasMonitorToRight)
                        ShellState.openControlCenter(visualWindow.screen.name);
                }
            }

            // ── Mask ──────────────────────────────────────────────
            mask: Region {
                Region {
                    item: bar
                }
                Region {
                    item: dashboardDrawer.panelItem
                }
                Region {
                    item: dashboardDrawer.footerMaskTarget
                }
                Region {
                    item: controlCenterDrawer.panelItem
                }
                Region {
                    item: systemDrawer.panelItem
                }
                Region {
                    item: terminalDrawer.panelItem
                }
                Region {
                    item: dock.panelItem
                }
                Region {
                    item: osd.panelItem
                }
                Region {
                    item: notificationPopup.panelItem
                }
                Region {
                    width: overviewLoader.shouldBeActive ? visualWindow.width : 0
                    height: overviewLoader.shouldBeActive ? visualWindow.height : 0
                }
                Region {
                    item: ShellState.activePopupItems.length > 0 ? ShellState.activePopupItems[0] : null
                }
                Region {
                    item: ShellState.activePopupItems.length > 1 ? ShellState.activePopupItems[1] : null
                }
                Region {
                    item: ShellState.activePopupItems.length > 2 ? ShellState.activePopupItems[2] : null
                }
                Region {
                    item: ShellState.activePopupItems.length > 3 ? ShellState.activePopupItems[3] : null
                }
                Region {
                    item: ShellState.activePopupItems.length > 4 ? ShellState.activePopupItems[4] : null
                }
                Region {
                    item: ShellState.activePopupItems.length > 5 ? ShellState.activePopupItems[5] : null
                }
                Region {
                    item: borderBezels.topBorderItem
                }
                Region {
                    item: borderBezels.bottomBorderItem
                }
                Region {
                    item: borderBezels.leftBorderItem
                }
                Region {
                    item: borderBezels.rightBorderItem
                }
            }
        }

        // ---------------------------------------------------------
        // 3. Reservation windows (bar height + bezel margins)
        // ---------------------------------------------------------
        ExclusionZones {
            screen: rootScope.screen
            barHeight: rootScope.topBarHeight
            bezelSize: rootScope.bezelSize
        }
    }
}
