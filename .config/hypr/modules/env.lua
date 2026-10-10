---@diagnostic disable: undefined-global

local p = require("modules.programs")
local browser = p.browser
local search_url = p.search_url

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Cursor follows darkman: seed it from the last mode here (apps inherit the
-- env), and ~/.local/share/darkman/cursor.sh swaps it live on every change.
local function darkman_mode()
	local f = io.open(os.getenv("HOME") .. "/.cache/darkman/mode.txt")
	if not f then
		return "dark"
	end
	local mode = f:read("l")
	f:close()
	return mode == "light" and "light" or "dark"
end
local cursor_theme = "catppuccin-mocha-" .. darkman_mode() .. "-cursors"

hl.env("XCURSOR_THEME", cursor_theme)
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", cursor_theme)
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GTK_IM_MODULE", "simple")
-- Overrides /etc/environment's BROWSER=firefox.
hl.env("BROWSER", browser)
hl.env("BROWSER_SEARCH", search_url)

-- lazygit: merge the base config with the Catppuccin preset (lavender accent)
-- whose flavour is swapped per light/dark by ~/.local/share/darkman/lazygit.sh.
-- Hyprland's `env` does not expand $HOME, so use an absolute path here.
hl.env(
	"LG_CONFIG_FILE",
	os.getenv("HOME") .. "/.config/lazygit/config.yml," .. os.getenv("HOME") .. "/.local/state/lazygit/theme.yml"
)

-- nvidia stuff
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
