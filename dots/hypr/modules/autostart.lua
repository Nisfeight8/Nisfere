hl.on("hyprland.start", function()
    -- ── Environment propagation — needed for XDG portals/dbus-aware
    -- services to correctly see WAYLAND_DISPLAY/XDG_CURRENT_DESKTOP ──
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- ── Idle / portals ───────────────────────────────────────────────
    hl.exec_cmd("hypridle")
    hl.exec_cmd("/usr/lib/xdg-desktop-portal-hyprland")
    hl.exec_cmd("/usr/lib/xdg-desktop-portal-gtk")
    hl.exec_cmd("/usr/lib/xdg-desktop-portal --replace")

    -- ── Polkit auth agent — confirmed installed (polkit-kde-agent).
    hl.exec_cmd("systemctl --user start plasma-polkit-agent.service")

    -- ── Wallpaper daemon (awww) ──────────────────────────────────────
    -- NOTE: awww recently DROPPED the `init` subcommand entirely (a
    -- breaking change) — you don't call anything to "restore" the
    -- wallpaper manually anymore. Per the official man page, the
    -- DAEMON ITSELF automatically restores the last-used wallpaper
    -- (cached under ~/.cache/awww) as soon as a monitor connects —
    -- starting awww-daemon is the only step needed.
    hl.exec_cmd("awww-daemon")

    -- ── Clipboard history — separate text/image watchers ──────────────────────────────
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- ── Bluetooth media buttons -> MPRIS ─────────────────────
    hl.exec_cmd("mpris-proxy")

    -- ── Housekeeping — auto-empty trash older than 30 days ───────────
    hl.exec_cmd("trash-empty 30")

    -- ── Daemon + shell ──────────────────────────────────────────
    hl.exec_cmd("systemctl --user start nisfere-daemon")
    hl.exec_cmd("quickshell > ~/.cache/nisfere/quickshell.log 2>&1")
end)