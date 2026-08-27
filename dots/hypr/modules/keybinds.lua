-- ~/.config/hypr/keybinds.lua

local mainMod = "SUPER"
local terminal = "alacritty"
local fileManager = "thunar"

-- ═══════════════════════════════════════════════════════════════════
-- CORE WINDOW / SESSION
-- ═══════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))                          -- open terminal
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())                              -- close active window
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))                       -- open file manager
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ mode = "fullscreen" }))  -- toggle fullscreen
hl.bind(mainMod .. " + V",      hl.dsp.window.float())                              -- toggle floating state
hl.bind(mainMod .. " + C",      hl.dsp.window.center())                             -- center the active floating window on screen
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("hyprshutdown"))                    -- open shutdown/session menu
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("firefox"))                         -- open browser

-- Pseudo-tiling (dwindle-only): keeps the window's set size instead of
-- filling its tile slot. Uncomment if you want a dedicated key for it.
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

-- ═══════════════════════════════════════════════════════════════════
-- SHELL (Quickshell IPC panels)
-- ═══════════════════════════════════════════════════════════════════

-- Tap SUPER alone (press+release, no other key) to open the launcher.
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { release = true })

hl.bind(mainMod .. " + R",           hl.dsp.exec_cmd("qs ipc call launcher toggle"))                -- app launcher
hl.bind(mainMod .. " + SPACE",       hl.dsp.exec_cmd("qs ipc call launcher toggle"))                -- app launcher (secondary key)
hl.bind(mainMod .. " + X",           hl.dsp.exec_cmd("qs ipc call powermenu toggle"))               -- power menu
hl.bind(mainMod .. " + T",           hl.dsp.exec_cmd("qs ipc call search toggle colors"))           -- theme/color switcher
hl.bind(mainMod .. " + D",           hl.dsp.exec_cmd("qs ipc call dashboard toggle"))               -- dashboard
hl.bind(mainMod .. " + N",           hl.dsp.exec_cmd("qs ipc call controlcenter toggle"))           -- control center
hl.bind(mainMod .. " + W",           hl.dsp.exec_cmd("qs ipc call search toggle wallpapers"))       -- wallpaper picker
hl.bind(mainMod .. " + L",           hl.dsp.exec_cmd("qs ipc call nisfere-lock trigger"))           -- lock screen
hl.bind(mainMod .. " + SHIFT + L",   hl.dsp.exec_cmd("systemctl suspend"), { locked = true })       -- suspend directly
hl.bind(mainMod .. " + SHIFT + V",   hl.dsp.exec_cmd("qs ipc call search toggle clipboard"))        -- clipboard manager
hl.bind(mainMod .. " + P",           hl.dsp.exec_cmd("qs ipc call tool toggle screenshot"))         -- screenshot tool
hl.bind(mainMod .. " + SHIFT + P",   hl.dsp.exec_cmd("qs ipc call tool toggle record"))             -- screen recorder
hl.bind(mainMod .. " + grave", hl.dsp.exec_cmd("qs ipc call terminal toggle"))                      -- terminal
 

-- Color picker: grabs a hex color under the cursor, copies it, and
-- shows a notification with the picked value.
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(
    "hyprpicker -f hex | wl-copy && notify-send 'Color picked' \"$(wl-paste)\" -a color-picker"
))

-- ═══════════════════════════════════════════════════════════════════
-- FOCUS MOVEMENT
-- ═══════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- ═══════════════════════════════════════════════════════════════════
-- MOVE WINDOW (swap position within the layout) — SHIFT + arrows
-- ═══════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- ═══════════════════════════════════════════════════════════════════
-- MOVE WINDOW TO ANOTHER MONITOR — SUPER + CTRL + arrows
-- ═══════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ monitor = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ monitor = "right" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ monitor = "up" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ monitor = "down" }))

-- ═══════════════════════════════════════════════════════════════════
-- RESIZE — Minus/Equal (relative resize, repeats while held)
-- ═══════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + Minus",         hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })  -- shrink width
hl.bind(mainMod .. " + Equal",         hl.dsp.window.resize({ x = 10,  y = 0, relative = true }), { repeating = true })  -- grow width
hl.bind(mainMod .. " + SHIFT + Minus", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })  -- shrink height
hl.bind(mainMod .. " + SHIFT + Equal", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })  -- grow height

-- ═══════════════════════════════════════════════════════════════════
-- GROUPS (tabbed windows) — auto_group is disabled in group.lua,
-- so windows only join a group through these binds or by dragging.
-- ═══════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + G",       hl.dsp.group.toggle())                          -- make the active window a group / ungroup it
hl.bind(mainMod .. " + comma",   hl.dsp.group.prev())                            -- switch to previous tab in the group
hl.bind(mainMod .. " + period",  hl.dsp.group.next())                            -- switch to next tab in the group
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.window.move({ out_of_group = true }))  -- remove the active window from its group
hl.bind(mainMod .. " + CTRL + G",  hl.dsp.group.lock())                          -- lock/unlock the group (blocks new windows from joining)

-- ═══════════════════════════════════════════════════════════════════
-- WORKSPACES 1–10 + move window to workspace
-- ═══════════════════════════════════════════════════════════════════

local vars = require("modules.variables")
local script_path = "bash $HOME/.config/hypr/scripts/smart_workspace.sh"
local per_mon = vars.workspacesPerMonitor

for i = 1, 10 do
  local key = tostring(i % 10)
  hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd(script_path .. " " .. i .. " focus " .. per_mon))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd(script_path .. " " .. i .. " movetoworkspace " .. per_mon))
end

-- Jump to the next/previous workspace across all monitors.
hl.bind(mainMod .. " + bracketright", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + bracketleft",  hl.dsp.focus({ workspace = "m-1" }))

-- Workspace overview grid.
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("qs ipc call overview toggle"))

-- ═══════════════════════════════════════════════════════════════════
-- SPECIAL WORKSPACE (scratchpad) — a hidden workspace toggled on any monitor
-- ═══════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))               -- show/hide the scratchpad
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))    -- send active window to the scratchpad

-- ═══════════════════════════════════════════════════════════════════
-- SCROLL THROUGH WORKSPACES — SUPER + mouse wheel
-- ═══════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ═══════════════════════════════════════════════════════════════════
-- MOUSE — drag to move, drag to resize
-- ═══════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })  -- SUPER + left click drag: move window
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })  -- SUPER + right click drag: resize window

-- ═══════════════════════════════════════════════════════════════════
-- MEDIA / VOLUME / BRIGHTNESS
-- ═══════════════════════════════════════════════════════════════════

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),  { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- Media control routed through the shell's MPRIS service, which picks
-- whichever player is actually playing instead of an arbitrary first match.
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("qs ipc call mpris next"),      { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("qs ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("qs ipc call mpris previous"),  { locked = true })

-- Function-key equivalents of the media keys above (F2–F4, F6–F8).
hl.bind("F3", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("F2", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("F4", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

hl.bind("F8", hl.dsp.exec_cmd("qs ipc call mpris next"),      { locked = true })
hl.bind("F7", hl.dsp.exec_cmd("qs ipc call mpris playPause"), { locked = true })
hl.bind("F6", hl.dsp.exec_cmd("qs ipc call mpris previous"),  { locked = true })

