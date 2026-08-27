pragma Singleton
import QtQuick
import Quickshell

import qs.services

// Fires theme-related commands at the daemon (wallpaper, colors,
// mode, settings) and caches the two lists that ONLY the daemon
// knows about — available wallpapers/themes, which come from
// directory scans, not from state.json.
//
// Deliberately does NOT track current theme state (colors, mode,
// wallpaper, style settings) — ThemeState.qml already watches
// state.json directly via FileView and reacts instantly to ANY
// change, whether it came from this shell, Hyprland, the daemon's
// own toggle_mode, or anything else. Round-tripping through the
// socket to re-fetch that same state after every action would just
// be a second, slower, less-reliable copy of the same data.
Singleton {
    id: root

    property var wallpapers: []
    property var themes: []

    // ── Signals ──────────────────────────────────────────────────
    signal wallpaperSet(bool success, string path)
    signal themeSet(bool success, string name)
    signal wallpapersLoaded(var list)
    signal themesLoaded(var list)
    signal settingUpdated(bool success, string key, string scope)
    signal chromaSettingUpdated(bool success, string key, var value, bool reapplied)

    Component.onCompleted: {
        SocketService.messageReceived.connect(_handleMessage);
    }

    // ── Incoming message router ───────────────────────────────────
    function _handleMessage(type, payload) {
        switch (type) {
        case "theme_applied":
            // set_wallpaper response has "wallpaper"; set_colors has "theme"
            if (payload.wallpaper !== undefined)
                root.wallpaperSet(payload.success ?? false, payload.wallpaper);
            else
                root.themeSet(payload.success ?? false, payload.theme ?? "");
            break;
        case "wallpapers_list":
            root.wallpapers = payload.wallpapers ?? [];
            root.wallpapersLoaded(root.wallpapers);
            break;
        case "themes_list":
            root.themes = payload.themes ?? [];
            root.themesLoaded(root.themes);
            break;
        case "setting_updated":
            root.settingUpdated(payload.success ?? false, payload.key ?? "", payload.scope ?? "shared");
            break;
        case "chroma_setting_updated":
            root.chromaSettingUpdated(payload.success ?? false, payload.key ?? "", payload.value, payload.reapplied ?? false);
            break;
        case "error":
            console.warn("ThemeActions: daemon error for action '" + (payload.action ?? "?") + "':", payload.error);
            break;
        }
    }

    // ── Wallpaper actions ────────────────────────────────────────
    function setWallpaper(path, applyColors, mode) {
        SocketService.sendCommand("theme", "set_wallpaper", {
            wallpaper_path: path,
            apply_colors: applyColors,
            mode: mode ?? "dark"
        });
    }

    function previewWallpaper(path) {
        SocketService.sendCommand("theme", "preview_wallpaper", {
            wallpaper_path: path
        });
    }

    // ── Color theme actions ──────────────────────────────────────
    function setColors(themeName, mode) {
        SocketService.sendCommand("theme", "set_colors", {
            theme_name: themeName,
            mode: mode ?? "dark"
        });
    }

    function toggleMode() {
        SocketService.sendCommand("theme", "toggle_mode", {});
    }

    // ── Settings — radius, fontName, widgetOpacity, or any
    // Hyprland-only key (windowGapsIn, blurEnabled, ...). scope
    // defaults to "shared" to match the daemon's own default. ──────
    function setSetting(key, value, scope) {
        SocketService.sendCommand("theme", "set_setting", {
            key: key,
            value: value,
            scope: scope ?? "shared"
        });
    }

    // ── Chroma extraction settings — algorithm, saturation,
    // bg_saturation, contrast, resize_to. Separate from setSetting()
    // above: these live outside the shared/shell/hyprland style
    // scopes entirely (see the daemon's StateManager), so there's no
    // scope parameter here. If a wallpaper-derived theme is currently
    // active, the daemon live-reapplies colors from it immediately —
    // reflected in the chromaSettingUpdated signal's `reapplied` flag,
    // and (separately) in ThemeState reacting to the resulting
    // state.json change, same as any other theme update. ───────────
    function setChromaSetting(key, value) {
        SocketService.sendCommand("theme", "set_chroma_setting", {
            key: key,
            value: value
        });
    }

    // ── Fetch methods (these two ARE only known by the daemon —
    // not part of state.json, so ThemeState can't give them) ────
    function fetchWallpapers() {
        SocketService.sendCommand("theme", "get_wallpapers", {});
    }

    function fetchThemes() {
        SocketService.sendCommand("theme", "get_themes", {});
    }
}