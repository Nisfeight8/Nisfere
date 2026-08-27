-- ~/.config/hypr/hyprland.lua

-- =========================================================================
-- Nisfere Shell - Master Hyprland Configuration (Lua API)
-- =========================================================================

local function load_module(module_name)
    local status, err = pcall(require, module_name)
    if not status then
        print("[Nisfere Error] Load Failed: " .. module_name)
        print("[Details]: " .. err)
    end
end

load_module("modules.environment")

load_module("modules.variables")


load_module("modules.monitors")

load_module("modules.input")
load_module("modules.general")
load_module("modules.misc")

load_module("modules.decoration")
load_module("modules.animations")
load_module("modules.group")
load_module("modules.gestures")

load_module("modules.windowrules")
load_module("modules.workspacerules")

load_module("modules.keybinds")

load_module("modules.autostart")