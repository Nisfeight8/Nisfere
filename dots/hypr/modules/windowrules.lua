-- ~/.config/hypr/windowrules.lua

-- ═══════════════════════════════════════════════════════════════════
-- GENERAL SANE DEFAULTS (from the official example)
-- ═══════════════════════════════════════════════════════════════════
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$", title = "^$",
        xwayland = true, float = true,
        fullscreen = false, pin = false,
    },
    no_focus = true,
})

-- ═══════════════════════════════════════════════════════════════════
-- YOUR APP-SPECIFIC RULES
-- ═══════════════════════════════════════════════════════════════════

hl.window_rule({
    name = "apply-thunar",
    match = { class = "^(thunar)$" },
    float = true, 
    center = true, 
    size = {800, 600},
    group = "set", -- <--- Opens Thunar as a group
})

hl.window_rule({
    name = "apply-alacritty",
    match = { class = "^(Alacritty)$" },
    float = true, 
    center = true, 
    size = {800, 600},
    group = "set", -- <--- Opens Alacritty as a group
})

hl.window_rule({
    name = "firefox-tile",
    match = { class = "^(firefox)$" },
    tile = true,
})

hl.window_rule({
    name = "spotify-tile",
    match = { class = "^(spotify)$" },
    tile = true,
})

hl.window_rule({
    name = "jetbrains-fix",
    match = { class = "^(jetbrains-.*)$", title = "^(win[0-9]+)$" },
    no_focus = true, float = true,
})

-- Additional JetBrains XWayland fix — separate issue from the one
-- above (empty initial_title dialogs/popups, not the win[0-9]+ ones).
-- See https://github.com/hyprwm/Hyprland/issues/4257
-- Uses the tag pattern (assign a tag, then apply properties to
-- anything with that tag) — cleaner than repeating the same match
-- criteria twice, and matches how caelestia organizes similar rules.
-- Additional JetBrains XWayland fix ...
hl.window_rule({
    name = "jb-tag",
    match = { class = "^jetbrains-.*", initial_title = "^$" },
    tag = "+jb",
})
hl.window_rule({
    name = "jb-focus",
    match = { tag = "jb" },
    focus_on_activate = true,
    no_initial_focus = true,
    float = false,
})
-- ═══════════════════════════════════════════════════════════════════
-- GAMING — Steam/Proton/gamescope. This is the well-known, standard
-- community fix — `immediate` reduces input/render latency for fullscreen
-- games, `idle_inhibit = "always"` stops the screen sleeping mid-game.
-- ═══════════════════════════════════════════════════════════════════
hl.window_rule({
    name = "gaming-latency-fix",
    match = { class = "(steam_app_(default|[0-9]+))|gamescope" },
    immediate = true,
    idle_inhibit = "always",
})

-- Steam's own windows (friends list, main client) rounded corners —
hl.window_rule({
    name = "steam-rounding",
    match = { class = "steam" },
    rounding = 10,
})
