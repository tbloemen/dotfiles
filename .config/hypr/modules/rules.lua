---@diagnostic disable: undefined-global

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

hl.window_rule({
	name = "prevent-gitkraken-from-going-fullscreen",
	match = { class = "GitKraken" },

	suppress_event = "fullscreen",
})

hl.window_rule({
	name = "float-notulen",
	match = { class = "notulen" },

	float = true,
})

hl.window_rule({
	-- Zoom's screen-share toolbar maps at y=0, under the bar, where it can't be clicked
	name = "zoom-share-toolbar-below-bar",
	match = { class = "zoom", title = "as_toolbar" },

	move = "((monitor_w-window_w)*0.5) 46",
})

hl.window_rule({
	name = "fix-jetbrains-flickering",
	match = { class = "jetbrains-.*" },

	no_initial_focus = true,
	float = true,
})

hl.window_rule({
	name = "fix-musescore",
	match = { class = "org.musescore.MuseScore" },

	no_initial_focus = true,
	float = true,
})
-- Example window rules that are useful

hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

-- Screenshot fix
hl.layer_rule({
	name = "no-anim-for-selection",
	match = { namespace = "selection" },
	no_anim = true,
})

-- The quickshell power menu animates itself; Hyprland's layer fade on top of
-- that doubles the fade-in.
hl.layer_rule({
	name = "no-anim-for-powermenu",
	match = { namespace = "quickshell:powermenu" },
	no_anim = true,
})

-- Same for the notification toasts, notification center, OSD, the cards,
-- launcher and wallpaper.
hl.layer_rule({
	name = "no-anim-for-quickshell-notifications",
	match = {
		namespace = "^quickshell:(notifications|notifcenter|osd|networkcard|launcher|wallpaper|mediacard|bluetoothcard|audiocard|calendarcard|displaycard|todoistcard|polkit)$",
	},
	no_anim = true,
})
