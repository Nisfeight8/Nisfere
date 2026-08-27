-- ~/.config/hypr/modules/group.lua
local vars = require("modules.variables")

hl.config({
    group = {
        auto_group = true,                  -- Automatically group new windows into the focused unlocked group
        insert_after_current = true,        -- New windows spawn after the current one
        focus_removed_window = true,
        drag_into_group = 1,                -- Allow dragging windows to merge them
        merge_groups_on_drag = true,
        merge_groups_on_groupbar = true,
        merge_floated_into_tiled_on_groupbar = false,
        group_on_movetoworkspace = false,
        
        col = {
            border_active          = vars.active_border,
            border_inactive        = vars.inactive_border,
            border_locked_active   = vars.active_border,
            border_locked_inactive = vars.inactive_border,
        },

        groupbar = {
            font_family = vars.fontName,
            font_size   = 11,
            gradients   = true,
            height      = 22,
            text_color  = vars.fg_color,

            col = {
                active          = vars.active_border,
                inactive        = vars.inactive_border,
                locked_active   = vars.active_border,
                locked_inactive = vars.inactive_border,
            },
        },
    },
})