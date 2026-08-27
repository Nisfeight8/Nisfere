local vars = require("modules.variables")

hl.config({
    binds = {
        hide_special_on_workspace_change = false,  -- keep the scratchpad open when switching workspaces (set true if you want it to auto-hide)
    },
    general = {
        layout = "dwindle",
        
        -- Gaps & Borders
        gaps_in = vars.windowGapsIn,
        gaps_out = vars.windowGapsOut,
        border_size = vars.windowBorderSize,
        
        -- Colors
        col = {
            active_border = vars.active_border,
            inactive_border = vars.inactive_border,
        },

        resize_on_border = true,
        hover_icon_on_border = true,
        allow_tearing = false,
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = true,
    },
})