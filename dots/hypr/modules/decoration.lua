-- ~/.config/hypr/modules/decoration.lua

local vars = require("modules.variables")

hl.config({
    decoration = {
        rounding = vars.windowRounding,

        -- Opacity
        active_opacity = vars.opacityActive,
        inactive_opacity = vars.opacityInactive,
        fullscreen_opacity = vars.opacityFullscreen,

        -- Blur settings
        blur = {
            enabled = vars.blurEnabled,
            size = vars.blurSize,
            passes = vars.blurPasses,
            ignore_opacity = true,
            new_optimizations = true,
            popups = vars.blurPopups,
            special = true,
        },

        -- Shadow settings
        shadow = {
            enabled = vars.shadowEnabled,
            range = vars.shadowRange,
            render_power = vars.shadowRenderPower,
            color = vars.shadow_color,
        }
    }
})