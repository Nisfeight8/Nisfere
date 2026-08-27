pragma Singleton
import QtQuick
import Quickshell

import qs.services

// General (non-color) style settings, actively consumed by the shell
// today. radius/fontName come from ThemeState.shared (Hyprland
// needs them too); everything else comes from ThemeState.shell
// (Quickshell-only knobs).
//
// A future settings UI does NOT need an escape hatch here — it can
// read ThemeState.shared / .shell / .hyprland directly, and write
// via ThemeActions.setSetting(key, value, scope). This file only
// exists to expose the small, named subset the shell's widgets
// actually bind to.
Singleton {
    id: root

    // Defaults match what Theme.qml used to hardcode directly.
    property bool enableWidgetBorders: true
    property string fontName: "Noto Nerd Font"
    property int radius: 20
    property int barHeight: 50
    property int padding: 6
    property int screenBorderSize: 10

    // General widget opacity (background/backgroundAlt alpha).
    // Deliberately a SINGLE value, not an active/inactive pair like
    // Hyprland's — the shell doesn't have a "focused window" concept
    // for its own widgets/drawers, so one value is all that makes
    // sense here even though it shares the same state.json with
    // Hyprland's own (separate, hyprland-scoped) opacityActive/
    // opacityInactive/opacityFullscreen.
    property real widgetOpacity: 1.0

    function _update() {
        const shared = ThemeState.shared;
        const shell = ThemeState.shell;

        if (shared.fontName !== undefined) root.fontName = shared.fontName;
        if (shared.radius !== undefined) root.radius = shared.radius;

        if (shell.enableWidgetBorders !== undefined) root.enableWidgetBorders = shell.enableWidgetBorders;
        if (shell.barHeight !== undefined) root.barHeight = shell.barHeight;
        if (shell.padding !== undefined) root.padding = shell.padding;
        if (shell.screenBorderSize !== undefined) root.screenBorderSize = shell.screenBorderSize;
        if (shell.widgetOpacity !== undefined) root.widgetOpacity = shell.widgetOpacity;
    }

    Component.onCompleted: _update()

    property Connections connections: Connections {
        target: ThemeState
        function onSharedChanged() {
            root._update();
        }
        function onShellChanged() {
            root._update();
        }
    }
}
