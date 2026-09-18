-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = { top = 15, right = 50, bottom = 20, left = 50 },
        gaps_workspaces = 0,
        border_size = 0,
        col = {
            active_border = { colors = {"rgba(A6A6A6ee)"}, angle = 45 },
            inactive_border = "rgba(545454aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 5,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a,
        },
        blur = {
            enabled = true,
            size = 12,
            passes = 3,

            ignore_opacity = true,
            new_optimizations = true,

            noise = 0.018,
            contrast = 0.95,
            brightness = 0.78,
            vibrancy = 0.12,
            vibrancy_darkness = 0,
        },
    },
})
