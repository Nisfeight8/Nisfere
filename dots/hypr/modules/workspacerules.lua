local vars = require("modules.variables")

local function assign_workspace_rules()
    local monitors = hl.get_monitors()

    table.sort(monitors, function(a, b)
        local a_laptop = a.name:match("^eDP") ~= nil
        local b_laptop = b.name:match("^eDP") ~= nil
        if a_laptop ~= b_laptop then return a_laptop end
        return a.name < b.name
    end)

    local names = {}
    for _, m in ipairs(monitors) do
        table.insert(names, m.name)
    end

    if #names == 0 then return nil end
    local per_mon = vars.workspacesPerMonitor

    local ws = 1
    for _, mon in ipairs(names) do
        for _ = 1, per_mon do
            hl.workspace_rule({ workspace = tostring(ws), monitor = mon })
            hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(ws), monitor = mon }))
            ws = ws + 1
        end
    end

    hl.workspace_rule({ workspace = "1", monitor = names[1], default = true })
    return names
end

-- Re-declaring the workspace<->monitor rules is safe on every reload
-- (theme changes included) — it's idempotent, no visible effect.
-- Forcing focus to workspace 1 is NOT safe to do unconditionally
-- here: this whole file re-runs on every Hyprland config reload, not
-- just real monitor changes (e.g. the theme daemon rewriting
-- hyprland.conf on a color/wallpaper change also triggers this same
-- reload path) — only a genuine monitor topology change should yank
-- focus.
assign_workspace_rules()

hl.on("monitor.added", function()
    if assign_workspace_rules() then
        hl.dispatch(hl.dsp.focus({ workspace = "1" }))
    end
end)
hl.on("monitor.removed", function()
    if assign_workspace_rules() then
        hl.dispatch(hl.dsp.focus({ workspace = "1" }))
    end
end)