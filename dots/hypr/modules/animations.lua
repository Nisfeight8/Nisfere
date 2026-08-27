--------------------------------------------------------------------------------
-- 1. Animation Master Switch
--------------------------------------------------------------------------------
hl.config({
    animations = {
        enabled = true,
    }
})

--------------------------------------------------------------------------------
-- 2. Animation Curves (Bezier)
--------------------------------------------------------------------------------
-- md3_decel: Starts quickly and brakes gently (Perfect for windows that slide in)
hl.curve("md3_decel", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })

-- md3_accel: Starts slowly and accelerates (Perfect for windows closing/exiting)
hl.curve("md3_accel", { type = "bezier", points = { {0.3, 0}, {0.8, 0.15} } })

-- overshot: Performs a slight "bounce" at the end (Perfect for switching workspaces)
hl.curve("overshot", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

-- smoothOut: Smooth fade-out
hl.curve("smoothOut", { type = "bezier", points = { {0.5, 0}, {0.99, 0.99} } })

--------------------------------------------------------------------------------
-- 3. Animation Rules
--------------------------------------------------------------------------------

-- WINDOWS: They appear and disappear by sliding instead of popping in.
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "md3_decel", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "md3_decel", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "md3_accel", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "md3_decel", style = "slide" })

-- LAYERS (Quickshell Drawers & Menus)
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "md3_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "md3_accel", style = "slide" })

-- FADES (Dimming): Smooth fade-in/fade-out
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "md3_decel" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 3, bezier = "smoothOut" })

-- WORKSPACES: When you switch workspaces, there is a very slight bounce.
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "md3_decel", style = "slidevert" })