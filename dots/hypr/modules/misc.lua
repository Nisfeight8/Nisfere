-- ~/.config/hypr/modules/misc.lua
local vars = require("modules.variables")

hl.config({
    misc = {
        disable_hyprland_logo        = true,
        force_default_wallpaper      = 0,

        animate_manual_resizes       = true,
        animate_mouse_windowdragging = true,

        focus_on_activate            = true,
        mouse_move_enables_dpms      = true,
        key_press_enables_dpms       = true,
        background_color             = vars.bg_color,

        allow_session_lock_restore   = true,
    },

    cursor = {
        no_hardware_cursors = false,
    },

    debug = {
        vfr = false,
    },
})