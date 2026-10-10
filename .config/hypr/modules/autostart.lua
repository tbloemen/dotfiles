---@diagnostic disable: undefined-global

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	-- quickshell is also the wallpaper (quickshell/WallpaperWindow.qml); it reads
	-- darkman's last mode from mode.txt itself, so nothing needs seeding.
	hl.exec_cmd("qs & hyprsunset")
	hl.exec_cmd("wlsunset -l 52.011578 -L 4.357068")
	-- GTK_IM_MODULE has to cross into the systemd user manager: ghostty runs as
	-- app-com.mitchellh.ghostty.service (app.slice), not as a Hyprland child, so
	-- it never inherits the `hl.env` above. Without it GTK4 falls back to the
	-- Wayland text-input-v3 IM context, which leaves dead-key composition to the
	-- compositor -- and Hyprland does not compose, so us(intl) dead keys
	-- (' " ` ^ ~) get swallowed and never emit a character. BROWSER crosses
	-- over for the same reason, so terminal tools agree with the launcher.
	hl.exec_cmd(
		"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE GTK_IM_MODULE BROWSER && systemctl --user start hyprland-session.target"
	)
	hl.exec_cmd("hypridle")
	-- Clipboard history for the launcher's clipboard mode (SUPER+SHIFT+V).
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("darkman run")
end)
