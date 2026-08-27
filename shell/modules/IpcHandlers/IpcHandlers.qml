import QtQuick
import Quickshell.Io
import qs.services

// All IPC handlers in one place, out of shell.qml. Each open/toggle
// goes through ShellState's methods (see ShellState.qml) — an IPC call
// has no "which screen did this come from" of its own, so it targets
// ShellState.focusedScreenName (whichever monitor Hyprland currently
// considers focused).
Item {
    id: root

    IpcHandler {
        target: "nisfere-lock"

        function trigger(): void {
            ShellState.isLocked = true;
        }
        function forceRestart(): void {
            LockerService.restart();      // test PAM restart directly, no lock/unlock involved
        }
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            ShellState.toggleOverview(ShellState.focusedScreenName);
        }
        function open(): void {
            ShellState.openOverview(ShellState.focusedScreenName);
        }
        function close(): void {
            ShellState.closeOverview();
        }
    }

    // Classic launcher — sugar over `search open apps` below (kept as
    // its own memorable target since it's such a common action —
    // keybind configs usually want something mnemonic here, not
    // "search toggle apps"). Was ShellState.toggleAppLauncher/
    // openAppLauncher/closeAppLauncher, none of which exist anymore.
    // "apps" has an empty keyword, so openDashboardSearch's existing
    // generic logic clears the query and lands you on browse mode with
    // the search bar available — exactly the classic launcher feel.
    // (There used to be a separate search-bar-less "appLauncherFull"
    // component/IPC target too — removed entirely, see ShellState.qml's
    // note on why.)
    IpcHandler {
        target: "launcher"

        function open(): void {
            ShellState.openDashboardSearch(ShellState.focusedScreenName, "apps");
        }
        function toggle(): void {
            ShellState.toggleDashboardSearch(ShellState.focusedScreenName, "apps");
        }
        function close(): void {
            ShellState.closeDashboard();
        }
    }

    IpcHandler {
        target: "powermenu"

        function toggle(): void {
            ShellState.togglePowerMenu(ShellState.focusedScreenName);
        }
        function open(): void {
            ShellState.openPowerMenu(ShellState.focusedScreenName);
        }
        function close(): void {
            ShellState.closePowerMenu();
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            ShellState.toggleDashboard(ShellState.focusedScreenName);
        }
        function open(): void {
            ShellState.openDashboard(ShellState.focusedScreenName);
        }
        function close(): void {
            ShellState.closeDashboard();
        }
        // Was ShellState.currentDashboardTab (doesn't exist — renamed
        // to dashboardTabsCurrentTab) + openDashboard (which doesn't
        // force "tabs" mode, just reopens whatever was last active —
        // openDashboardTabs is the one that actually guarantees you
        // land on the tabs page with the requested tab selected).
        function openTab(index: int): void {
            ShellState.dashboardTabsCurrentTab = index;
            ShellState.openDashboardTabs(ShellState.focusedScreenName);
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            ShellState.toggleControlCenter(ShellState.focusedScreenName);
        }
        function open(): void {
            ShellState.openControlCenter(ShellState.focusedScreenName);
        }
        function close(): void {
            ShellState.closeControlCenter();
        }
    }

    // Dropdown terminal — keyboard-triggered now, deliberately NOT
    // hover-triggered like Dashboard/ControlCenter/SystemDrawer (see
    // chat: a terminal is a tool you deliberately reach for, not
    // something you glance at — a global hotkey is also unambiguous
    // regardless of where the cursor happens to be, unlike hover,
    // which also frees up the bottom screen edge entirely for a future
    // Dock to use instead).
    IpcHandler {
        target: "terminal"

        function toggle(): void {
            ShellState.toggleTerminalDrawer(ShellState.focusedScreenName);
        }
        function open(): void {
            ShellState.openTerminalDrawer(ShellState.focusedScreenName);
        }
        function close(): void {
            ShellState.closeTerminalDrawer();
        }
    }

    IpcHandler {
        target: "search"

        function open(providerId: string): void {
            ShellState.openDashboardSearch(ShellState.focusedScreenName, providerId);
        }
        function toggle(providerId: string): void {
            ShellState.toggleDashboardSearch(ShellState.focusedScreenName, providerId);
        }
        function close(): void {
            ShellState.closeDashboard();
        }
    }

    // ── Any standalone top-level tool — one generic target instead of
    // one IpcHandler block per tool, same reasoning as "search" above.
    // Usage: `qs ipc call tool open docker`, `qs ipc call tool toggle
    // settings`, etc.
    IpcHandler {
        target: "tool"

        function open(componentId: string): void {
            ShellState.openDashboardComponent(ShellState.focusedScreenName, componentId);
        }
        function toggle(componentId: string): void {
            ShellState.toggleDashboardComponent(ShellState.focusedScreenName, componentId);
        }
        function close(): void {
            ShellState.closeDashboard();
        }
    }
}
