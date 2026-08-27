pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Color-related properties only — derived from ThemeState.shared.
// Colors always live in the 'shared' scope: both the shell and
// Hyprland need them. Sibling to Settings.qml (same underlying
// state, different named slice of it). Theme.qml aggregates both
// into the single API the rest of the shell already uses.
Singleton {
    id: root

    // ── Defaults: Catppuccin Mocha (used until state.json loads, or
    // for any key it doesn't contain yet) ──────────────────────────
    property color background: "#1e1e2e"
    property color backgroundAlt: "#252535"
    property color foreground: "#cdd6f4"
    property color foregroundAlt: "#8f95aa"

    property color cursor: "#cdd6f4"
    property color borderColor: "#313244"
    property color selected: "#cba6f7"

    property color color0: "#45475a"
    property color color1: "#f38ba8"
    property color color2: "#a6e3a1"
    property color color3: "#f9e2af"
    property color color4: "#89b4fa"
    property color color5: "#cba6f7"
    property color color6: "#94e2d5"
    property color color7: "#bac2de"
    property color color8: "#585b70"
    property color color9: "#f38ba8"
    property color color10: "#a6e3a1"
    property color color11: "#f9e2af"
    property color color12: "#89b4fa"
    property color color13: "#cba6f7"
    property color color14: "#94e2d5"
    property color color15: "#a6adc8"

    // Metadata passthrough — same field names Theme.qml already exposed
    readonly property string wallpaper: ThemeState.wallpaper
    readonly property string mode: ThemeState.mode
    readonly property string sourceType: ThemeState.sourceType
    readonly property string sourceName: ThemeState.sourceName

    function _update() {
        const c = ThemeState.shared;

        if (c.background) root.background = c.background;
        if (c.foreground) root.foreground = c.foreground;
        if (c.cursor) root.cursor = c.cursor;
        if (c.backgroundAlt) root.backgroundAlt = c.backgroundAlt;
        if (c.borderColor) root.borderColor = c.borderColor;

        // selected = color4 (accent, matches wallust palette convention)
        if (c.accent) root.selected = c.accent;

        if (c.color0) root.color0 = c.color0;
        if (c.color1) root.color1 = c.color1;
        if (c.color2) root.color2 = c.color2;
        if (c.color3) root.color3 = c.color3;
        if (c.color4) root.color4 = c.color4;
        if (c.color5) root.color5 = c.color5;
        if (c.color6) root.color6 = c.color6;
        if (c.color7) root.color7 = c.color7;
        if (c.color8) root.color8 = c.color8;
        if (c.color9) root.color9 = c.color9;
        if (c.color10) root.color10 = c.color10;
        if (c.color11) root.color11 = c.color11;
        if (c.color12) root.color12 = c.color12;
        if (c.color13) root.color13 = c.color13;
        if (c.color14) root.color14 = c.color14;
        if (c.color15) root.color15 = c.color15;
    }

    Component.onCompleted: _update()

    property Connections connections: Connections {
        target: ThemeState
        function onSharedChanged() {
            root._update();
        }
    }
}
