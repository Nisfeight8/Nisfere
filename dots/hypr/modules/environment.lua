-- ~/.config/hypr/modules/environment.lua

local vars = require("modules.variables")

-- ── Cursors ──────────────────────────────────────────────────────────
hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", tostring(vars.cursorSize))

-- ── Qt Framework ─────────────────────────────────────────────────────
hl.env("QT_QPA_PLATFORMTHEME", "qtengine")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

-- ── Wayland Session (XDG) ────────────────────────────────────────────
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- ── Toolkit Backends (GTK, SDL, Electron, Firefox) ───────────────────
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- ── Others ───────────────────────────────────────────────────────────
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")