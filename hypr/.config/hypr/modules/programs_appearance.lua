hl.window_rule({
	name = "kitty-glass",
	match = {
		class = "kitty",
	},

	-- active / inactive / fullscreen
	opacity = "0.76 override 0.76 override 1.0 override",

	-- Kitty 單獨使用 xray
	xray = true,

	-- 外觀
	rounding = 5,
	rounding_power = 3.0,
	border_size = 1,
    border_color = "rgba(ffffff25) rgba(ffffff12)",
})

hl.layer_rule({
    name = "quickshell-launcher-glass",
    match = {
        namespace = "^quickshell-launcher$",
    },

    blur = true,
    xray = true,
    ignore_alpha = 0.01,
})


hl.layer_rule({
    name = "quickshell-topbar-glass",
    match = {
        namespace = "^quickshell-topbar$",
    },

    blur = true,
    xray = true,
    ignore_alpha = 0.01,
})

hl.layer_rule({
    name = "quickshell-inputmethod-glass",
    match = {
        namespace = "^quickshell-inputmethod$",
    },
    blur = true,
    xray = true,
    ignore_alpha = 0.01,
})
