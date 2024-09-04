--[[

     Powerarrow Awesome WM theme
     github.com/lcpz

--]]

local gears = require("gears")
local lain = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi
local beautiful = require("beautiful")

local math, string, os = math, string, os
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

local theme = {}
theme.dir = os.getenv("HOME") .. "/.config/awesome/themes/powerarrow"
theme.wallpaper = theme.dir .. "/wall.png"
theme.font = "JetBrainsMono Nerd Font Regular 10"
theme.fg_normal = "#cdd6f4"
theme.fg_focus = "#cba6f7" -- Might change to blue
-- theme.fg_urgent = "#f38ba8"
theme.fg_urgent = "#cdd6f4"
theme.bg_normal = "#1e1e2e"
theme.bg_focus = "#313244"
theme.bg_urgent = "#585b70"
theme.taglist_fg_focus = theme.fg_focus
theme.tasklist_bg_focus = "#181825"
theme.tasklist_fg_focus = theme.fg_focus
theme.border_width = dpi(2)
theme.border_normal = "#6c7086"
theme.border_focus = "#b4befe"
theme.border_marked = "#f9e2af"
theme.titlebar_bg_focus = "#3F3F3F"
theme.titlebar_bg_normal = "#3F3F3F"
theme.titlebar_bg_focus = "#313244"
theme.titlebar_bg_normal = "#1e1e2e"
theme.titlebar_fg_focus = theme.fg_focus
theme.menu_height = dpi(16)
theme.menu_width = dpi(140)
theme.menu_submenu_icon = theme.dir .. "/icons/submenu.png"
theme.awesome_icon = theme.dir .. "/icons/awesome.png"
theme.taglist_squares_sel = theme.dir .. "/icons/square_sel.png"
theme.taglist_squares_unsel = theme.dir .. "/icons/square_unsel.png"
theme.layout_tile = theme.dir .. "/icons/tile.png"
theme.layout_tileleft = theme.dir .. "/icons/tileleft.png"
theme.layout_tilebottom = theme.dir .. "/icons/tilebottom.png"
theme.layout_tiletop = theme.dir .. "/icons/tiletop.png"
theme.layout_fairv = theme.dir .. "/icons/fairv.png"
theme.layout_fairh = theme.dir .. "/icons/fairh.png"
theme.layout_spiral = theme.dir .. "/icons/spiral.png"
theme.layout_dwindle = theme.dir .. "/icons/dwindle.png"
theme.layout_max = theme.dir .. "/icons/max.png"
theme.layout_fullscreen = theme.dir .. "/icons/fullscreen.png"
theme.layout_magnifier = theme.dir .. "/icons/magnifier.png"
theme.layout_floating = theme.dir .. "/icons/floating.png"
theme.widget_ac = theme.dir .. "/icons/ac.png"
theme.widget_battery = theme.dir .. "/icons/battery.png"
theme.widget_battery_low = theme.dir .. "/icons/battery_low.png"
theme.widget_battery_empty = theme.dir .. "/icons/battery_empty.png"
theme.widget_brightness = theme.dir .. "/icons/brightness.png"
theme.widget_mem = theme.dir .. "/icons/mem.png"
theme.widget_cpu = theme.dir .. "/icons/cpu.png"
theme.widget_temp = theme.dir .. "/icons/temp.png"
theme.widget_net = theme.dir .. "/icons/net.png"
theme.widget_hdd = theme.dir .. "/icons/hdd.png"
theme.widget_music = theme.dir .. "/icons/note.png"
theme.widget_music_on = theme.dir .. "/icons/note_on.png"
theme.widget_music_pause = theme.dir .. "/icons/pause.png"
theme.widget_music_stop = theme.dir .. "/icons/stop.png"
theme.widget_vol = theme.dir .. "/icons/vol.png"
theme.widget_vol_low = theme.dir .. "/icons/vol_low.png"
theme.widget_vol_no = theme.dir .. "/icons/vol_no.png"
theme.widget_vol_mute = theme.dir .. "/icons/vol_mute.png"
theme.widget_mail = theme.dir .. "/icons/mail.png"
theme.widget_mail_on = theme.dir .. "/icons/mail_on.png"
theme.widget_task = theme.dir .. "/icons/task.png"
theme.widget_scissors = theme.dir .. "/icons/scissors.png"
theme.tasklist_plain_task_name = true
theme.tasklist_disable_icon = true
theme.useless_gap = 5
theme.titlebar_close_button_focus = theme.dir .. "/icons/titlebar/close_focus.png"
theme.titlebar_close_button_normal = theme.dir .. "/icons/titlebar/close_normal.png"
theme.titlebar_ontop_button_focus_active = theme.dir .. "/icons/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = theme.dir .. "/icons/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive = theme.dir .. "/icons/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = theme.dir .. "/icons/titlebar/ontop_normal_inactive.png"
theme.titlebar_sticky_button_focus_active = theme.dir .. "/icons/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = theme.dir .. "/icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive = theme.dir .. "/icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = theme.dir .. "/icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_floating_button_focus_active = theme.dir .. "/icons/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = theme.dir .. "/icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive = theme.dir .. "/icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = theme.dir .. "/icons/titlebar/floating_normal_inactive.png"
theme.titlebar_maximized_button_focus_active = theme.dir .. "/icons/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = theme.dir .. "/icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive = theme.dir .. "/icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = theme.dir .. "/icons/titlebar/maximized_normal_inactive.png"

local markup = lain.util.markup
local separators = lain.util.separators

local clock = awful.widget.watch("date +'%a %d %b %R'", 60, function(widget, stdout)
	widget:set_markup(" " .. markup.font(theme.font, stdout))
end)

-- Calendar
theme.cal = lain.widget.cal({
	--cal = "cal --color=always",
	attach_to = { clock },
	notification_preset = {
		font = theme.font,
		fg = theme.fg_normal,
		bg = theme.bg_normal,
	},
})

-- ALSA volume
theme.volume = lain.widget.alsabar({
	--togglechannel = "IEC958,3",
	notification_preset = { font = theme.font, fg = theme.fg_normal },
})

-- MEM
local memicon = wibox.widget.imagebox(theme.widget_mem)
local mem = lain.widget.mem({
	settings = function()
		widget:set_markup(markup.font(theme.font, " " .. mem_now.used .. "MB "))
	end,
})

-- CPU
local cpuicon = wibox.widget.imagebox(theme.widget_cpu)
local cpu = lain.widget.cpu({
	settings = function()
		widget:set_markup(markup.font(theme.font, " " .. cpu_now.usage .. "% "))
	end,
})

-- Coretemp (lain, average)
local temp = lain.widget.temp({
	settings = function()
		widget:set_markup(markup.font(theme.font, " " .. coretemp_now .. "°C "))
	end,
})
--]]
local tempicon = wibox.widget.imagebox(theme.widget_temp)

-- Battery
local baticon = wibox.widget.imagebox(theme.widget_battery)
local bat = lain.widget.bat({
	settings = function()
		if bat_now.status and bat_now.status ~= "N/A" then
			if bat_now.ac_status == 1 then
				widget:set_markup(markup.font(theme.font, " AC "))
				baticon:set_image(theme.widget_ac)
				return
			elseif not bat_now.perc and tonumber(bat_now.perc) <= 5 then
				baticon:set_image(theme.widget_battery_empty)
			elseif not bat_now.perc and tonumber(bat_now.perc) <= 15 then
				baticon:set_image(theme.widget_battery_low)
			else
				baticon:set_image(theme.widget_battery)
			end
			widget:set_markup(markup.font(theme.font, " " .. bat_now.perc .. "% "))
		else
			widget:set_markup()
			baticon:set_image(theme.widget_ac)
		end
	end,
})

-- Net
local neticon = wibox.widget.imagebox(theme.widget_net)
local net = lain.widget.net({
	settings = function()
		widget:set_markup(markup.font(theme.font, " " .. net_now.received .. " ↓↑ " .. net_now.sent .. " "))
	end,
})

-- Brightness
local brighticon = wibox.widget.imagebox(theme.widget_brightness)
-- If you use xbacklight, comment the line with "light -G" and uncomment the line bellow
-- local brightwidget = awful.widget.watch('xbacklight -get', 0.1,
local brightwidget = awful.widget.watch("brightnessctl g", 0.1, function(widget, stdout, stderr, exitreason, exitcode)
	local brightness_level = tonumber(string.format("%.0f", stdout)) / 256 * 100
	widget:set_markup(markup.font(theme.font, " " .. brightness_level .. "%"))
end)

-- MPD
local mpdicon = wibox.widget.imagebox(theme.widget_music)
local mpris = lain.widget.mpris({
	settings = function()
		widget:set_markup(markup.font(theme.font, mpris_now.artist .. " - " .. mpris_now.title .. " "))
	end,
})

-- Separators
local arrow = separators.arrow_left

local if_playing = {
	arrow("#dc8a78", theme.bg_normal),
	wibox.container.background(
		wibox.container.margin(
			wibox.widget({ mpdicon, mpris.widget, layout = wibox.layout.align.horizontal }),
			dpi(3),
			dpi(6)
		),
		theme.bg_normal
	),
	arrow(theme.bg_normal, "#40a02b"),
}

function theme.powerline_rl(cr, width, height)
	local arrow_depth, offset = height / 2, 0

	-- Avoid going out of the (potential) clip area
	if arrow_depth < 0 then
		width = width + 2 * arrow_depth
		offset = -arrow_depth
	end

	cr:move_to(offset + arrow_depth, 0)
	cr:line_to(offset + width, 0)
	cr:line_to(offset + width - arrow_depth, height / 2)
	cr:line_to(offset + width, height)
	cr:line_to(offset + arrow_depth, height)
	cr:line_to(offset, height / 2)

	cr:close_path()
end

local function pl(widget, bgcolor, padding)
	return wibox.container.background(wibox.container.margin(widget, dpi(16), dpi(16)), bgcolor, theme.powerline_rl)
end

function theme.at_screen_connect(s, numScreens)
	-- Quake application
	s.quake = lain.util.quake({ app = awful.util.terminal })

	-- Tags
	if numScreens ~= 2 then
		awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])
		awful.util.spawn("spotify")
		awful.util.spawn("flatpak run com.todoist.Todoist")
		awful.util.spawn("gitkraken")
		awful.util.spawn("thunderbird")
		awful.util.spawn("firefox --new-window web.whatsapp.com", { tag = "whatsapp" })
	else
		if s.index == 2 then
			awful.tag({ "main", "research", "opt", "mail", "messages" }, s, awful.layout.layouts[1])
		elseif s.index == 1 then
			awful.tag({ "git", "todoist", "whatsapp", "spotify" }, s, awful.layout.layouts[1])
		end
	end

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(my_table.join(
		awful.button({}, 1, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 2, function()
			awful.layout.set(awful.layout.layouts[1])
		end),
		awful.button({}, 3, function()
			awful.layout.inc(-1)
		end),
		awful.button({}, 4, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 5, function()
			awful.layout.inc(-1)
		end)
	))
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, awful.util.taglist_buttons)

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)

	-- Create the wibox
	s.mywibox =
		awful.wibar({ position = "top", screen = s, height = dpi(16), bg = theme.bg_normal, fg = theme.fg_normal })

	local myColors = {
		"#1e1e2e",
		"#33294e",
		"#55336e",
		"#823e8e",
		"#ad499f",
		"#cd5399",
		"#ed5e87",
	}

	beautiful.bg_systray = myColors[5]

	-- Add widgets to the wibox
	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			--spr,

			s.mytaglist,
			-- s.mypromptbox,
		},
		s.mytasklist,
		{ -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			arrow(myColors[1], myColors[2]),
			wibox.container.background(
				wibox.container.margin(
					wibox.widget({ mpdicon, mpris.widget, layout = wibox.layout.align.horizontal }),
					dpi(3),
					dpi(3)
				),
				myColors[2]
			),
			-- using separators
			arrow(myColors[2], myColors[3]),
			wibox.container.background(
				wibox.container.margin(
					wibox.widget({ nil, neticon, net.widget, layout = wibox.layout.align.horizontal }),
					dpi(3),
					dpi(3)
				),
				myColors[3]
			),
			arrow(myColors[3], myColors[4]),
			wibox.container.background(
				wibox.container.margin(
					wibox.widget({ cpuicon, cpu.widget, layout = wibox.layout.align.horizontal }),
					dpi(3),
					dpi(3)
				),
				myColors[4]
			),
			arrow(myColors[4], myColors[5]),
			wibox.container.background(wibox.container.margin(wibox.widget.systray(), dpi(3), dpi(3)), myColors[5]),
			arrow(myColors[5], myColors[6]),
			wibox.container.background(
				wibox.container.margin(
					wibox.widget({ baticon, bat.widget, layout = wibox.layout.align.horizontal }),
					dpi(3),
					dpi(3)
				),
				myColors[6]
			),
			arrow(myColors[6], myColors[7]),
			wibox.container.background(wibox.container.margin(clock, dpi(4), dpi(8)), myColors[7]),
			arrow(myColors[7], "alpha"),
			s.mylayoutbox,
		},
	})
end

return theme
