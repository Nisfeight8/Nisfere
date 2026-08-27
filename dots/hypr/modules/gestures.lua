hl.config({
    gestures = {
        workspace_swipe_distance           = 200,
        workspace_swipe_cancel_ratio       = 0.3,
        workspace_swipe_min_speed_to_force = 20,
        workspace_swipe_direction_lock     = true,
        workspace_swipe_create_new         = true, 
    }
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})